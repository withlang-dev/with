// RecipeInterp — a Conan recipe's methods, evaluated.
//
// A recipe is a Python class, and what it says about a package (which
// libraries it holds, which of them a consumer links, which other packages
// they need, what each platform and option changes) is said in Python:
// local variables, `if`/`elif`, `for`, lists that grow by `append`, helper
// properties of the recipe's own. Reading that by matching lines is a table
// of special cases that grows one package at a time. This module reads it the
// way Conan does: it parses the recipe and runs the method, against a model
// of what a recipe sees (`self.settings`, `self.options`, `self.cpp_info`).
//
// It is an interpreter for the subset of Python recipes are written in, not
// for Python: no imports are executed and nothing outside the recipe is
// reached. A name it does not model evaluates to Unknown, Unknown spreads
// through whatever uses it, and a branch decided by an Unknown is not taken:
// it is reported (`notes`), never guessed. Nothing here names a package.

use std.string.StringBuilder
use compiler.Runtime

extern fn str_from_byte(b: i32) -> str

// ── Tokens ───────────────────────────────────────────────────────────

const PT_NAME = 1
const PT_NUM = 2
const PT_STR = 3
const PT_OP = 4
const PT_NEWLINE = 5
const PT_INDENT = 6
const PT_DEDENT = 7
const PT_EOF = 8

type PyTok { kind: i32, text: str, line: i32 }

fn py_is_name_start(c: u8) -> bool: (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
fn py_is_digit(c: u8) -> bool: c >= '0' and c <= '9'
fn py_is_name_char(c: u8) -> bool: py_is_name_start(c) or py_is_digit(c)

fn py_tok(kind: i32, text: &str, line: i32): PyTok { kind, text: text.to_owned(), line }

// Whether `word` (already lowercase) is a string prefix: r, b, f, u and
// their two-letter combinations.
fn py_is_string_prefix(word: &str) -> bool:
    if word.len() == 0 or word.len() > 2: return false
    for i in 0..word.len() as i32:
        let c = word[i]
        if c != 'r' and c != 'b' and c != 'f' and c != 'u' and c != 'R' and c != 'B' and c != 'F' and c != 'U': return false
    true

// A string literal's body with its escapes resolved (`raw` leaves them).
fn py_unescape(body: &str, raw: bool) -> str:
    if raw or body.find("\\") < 0: return body.to_owned()
    var out = StringBuilder.with_capacity(body.len())
    var i = 0
    let n = body.len() as i32
    var start = 0
    while i < n:
        if body[i] != '\\' or i + 1 >= n:
            i = i + 1
            continue
        out.push_str(body.slice(start, i))
        let e = body[i + 1]
        if e == 'n': out.push_str("\n")
        else if e == 't': out.push_str("\t")
        else if e == 'r': out.push_str("\r")
        else if e == '\n': out.push_str("")
        else if e == '\\' or e == '\'' or e == '"': out.push_str(body.slice(i + 1, i + 2))
        else: out.push_str(body.slice(i, i + 2))
        i = i + 2
        start = i
    out.push_str(body.slice(start, n))
    out.to_str()

// The end of an f-string replacement field's expression: the index of the
// `!r` conversion or `:spec` that follows it at nesting depth 0, or the
// field's end.
fn py_fstring_expr_end(field: &str) -> i32:
    var depth = 0
    var quote: u8 = 0
    let n = field.len() as i32
    for i in 0..n:
        let c = field[i]
        if quote != 0:
            if c == quote: quote = 0
            continue
        if c == '"' or c == '\'': quote = c
        else if c == '(' or c == '[' or c == '{': depth = depth + 1
        else if c == ')' or c == ']' or c == '}': depth = depth - 1
        else if depth == 0 and c == ':': return i
        else if depth == 0 and c == '!' and i + 1 < n and field[i + 1] != '=': return i
    n

// An f-string as tokens: `fstr[`, then its literal parts as strings and each
// replacement field as `f{` expression-tokens `f}`, then `]fstr`.
fn py_lex_fstring(body: &str, line: i32, out0: List[PyTok]) -> List[PyTok]:
    var out = out0
    out.push(py_tok(PT_OP, "fstr[", line))
    var literal = StringBuilder.new()
    var i = 0
    let n = body.len() as i32
    while i < n:
        let c = body[i]
        if c == '{' and i + 1 < n and body[i + 1] == '{':
            literal.push_str("{")
            i = i + 2
        else if c == '}' and i + 1 < n and body[i + 1] == '}':
            literal.push_str("}")
            i = i + 2
        else if c == '{':
            var depth = 1
            var j = i + 1
            while j < n and depth > 0:
                if body[j] == '{': depth = depth + 1
                if body[j] == '}': depth = depth - 1
                j = j + 1
            let field = body.slice(i + 1, j - 1)
            out.push(py_tok(PT_STR, literal.to_str(), line))
            literal = StringBuilder.new()
            out.push(py_tok(PT_OP, "f{", line))
            let inner = py_lex(field.slice(0, py_fstring_expr_end(field)))
            for t in inner:
                if t.kind == PT_NEWLINE or t.kind == PT_INDENT or t.kind == PT_DEDENT or t.kind == PT_EOF: continue
                out.push(py_tok(t.kind, t.text, line))
            out.push(py_tok(PT_OP, "f}", line))
            i = j
        else:
            literal.push_str(body.slice(i, i + 1))
            i = i + 1
    out.push(py_tok(PT_STR, literal.to_str(), line))
    out.push(py_tok(PT_OP, "]fstr", line))
    out

fn py_lex(src: &str) -> List[PyTok]:
    var out: List[PyTok] = List.new()
    var indents: List[i32] = List.new()
    indents.push(0)
    let n = src.len() as i32
    var i: i32 = 0
    var line: i32 = 1
    var depth = 0
    var at_line_start = true
    while i < n:
        if at_line_start and depth == 0:
            // Measure the indentation; a blank or comment-only line has none.
            var col = 0
            var j = i
            while j < n and (src[j] == ' ' or src[j] == '\t'):
                col = if src[j] == '\t': (col / 8 + 1) * 8 else: col + 1
                j = j + 1
            if j >= n: break
            if src[j] == '\n':
                i = j + 1
                line = line + 1
                continue
            if src[j] == '\r':
                i = j + 1
                continue
            if src[j] == '#':
                while j < n and src[j] != '\n': j = j + 1
                i = j
                continue
            i = j
            at_line_start = false
            if col > indents[indents.len() as i32 - 1]:
                indents.push(col)
                out.push(py_tok(PT_INDENT, "", line))
            else:
                while col < indents[indents.len() as i32 - 1]:
                    let _ = indents.pop()
                    out.push(py_tok(PT_DEDENT, "", line))
            continue
        let c = src[i]
        if c == '\n':
            line = line + 1
            i = i + 1
            if depth == 0:
                if out.len() > 0 and out[out.len() as i32 - 1].kind != PT_NEWLINE: out.push(py_tok(PT_NEWLINE, "", line - 1))
                at_line_start = true
            continue
        if c == ' ' or c == '\t' or c == '\r':
            i = i + 1
            continue
        if c == '#':
            while i < n and src[i] != '\n': i = i + 1
            continue
        if c == '\\' and i + 1 < n and (src[i + 1] == '\n' or src[i + 1] == '\r'):
            // A continued line.
            i = i + 1
            while i < n and src[i] != '\n': i = i + 1
            i = i + 1
            line = line + 1
            continue
        if py_is_name_start(c):
            var j = i
            while j < n and py_is_name_char(src[j]): j = j + 1
            let word = src.slice(i, j)
            if j < n and (src[j] == '"' or src[j] == '\'') and py_is_string_prefix(word):
                i = j
                // Fall through to the string below, with the prefix known.
                let raw = word.contains("r") or word.contains("R")
                let is_f = word.contains("f") or word.contains("F")
                let (body, next, lines) = py_lex_string_body(src, i)
                if is_f: out = py_lex_fstring(py_unescape(body, raw), line, move out)
                else: out.push(py_tok(PT_STR, py_unescape(body, raw), line))
                line = line + lines
                i = next
                continue
            out.push(py_tok(PT_NAME, word, line))
            i = j
            continue
        if py_is_digit(c):
            var j = i
            while j < n and (py_is_name_char(src[j]) or src[j] == '.'): j = j + 1
            out.push(py_tok(PT_NUM, src.slice(i, j), line))
            i = j
            continue
        if c == '"' or c == '\'':
            let (body, next, lines) = py_lex_string_body(src, i)
            out.push(py_tok(PT_STR, py_unescape(body, false), line))
            line = line + lines
            i = next
            continue
        if c == '(' or c == '[' or c == '{': depth = depth + 1
        if c == ')' or c == ']' or c == '}': depth = depth - 1
        if i + 2 < n:
            let three = src.slice(i, i + 3)
            if three == "**=" or three == "//=" or three == "...":
                out.push(py_tok(PT_OP, three, line))
                i = i + 3
                continue
        if i + 1 < n:
            let two = src.slice(i, i + 2)
            if two == "==" or two == "!=" or two == "<=" or two == ">=" or two == "+=" or two == "-=" or two == "*=" or two == "/=" or two == "->" or two == "**" or two == "//" or two == ":=" or two == "|=" or two == "%=":
                out.push(py_tok(PT_OP, two, line))
                i = i + 2
                continue
        out.push(py_tok(PT_OP, src.slice(i, i + 1), line))
        i = i + 1
    if out.len() > 0 and out[out.len() as i32 - 1].kind != PT_NEWLINE: out.push(py_tok(PT_NEWLINE, "", line))
    while indents.len() > 1:
        let _ = indents.pop()
        out.push(py_tok(PT_DEDENT, "", line))
    out.push(py_tok(PT_EOF, "", line))
    out

// The body of the string literal whose opening quote is at `at`: the text
// between the quotes (escapes untouched), the index after the closing quote,
// and the newlines it spans.
fn py_lex_string_body(src: &str, at: i32) -> (str, i32, i32):
    let n = src.len() as i32
    let q = src[at]
    let triple = at + 2 < n and src[at + 1] == q and src[at + 2] == q
    var i = if triple: at + 3 else: at + 1
    let start = i
    var lines = 0
    while i < n:
        let c = src[i]
        if c == '\\' and i + 1 < n:
            if src[i + 1] == '\n': lines = lines + 1
            i = i + 2
            continue
        if c == '\n': lines = lines + 1
        if c == q:
            if not triple: return (src.slice(start, i).to_owned(), i + 1, lines)
            if i + 2 < n and src[i + 1] == q and src[i + 2] == q: return (src.slice(start, i).to_owned(), i + 3, lines)
        i = i + 1
    (src.slice(start, n).to_owned(), n, lines)

// ── Syntax tree ──────────────────────────────────────────────────────

const N_NAME = 1        // s
const N_STR = 2         // s
const N_FSTR = 3        // kids: parts
const N_NUM = 4         // s
const N_CONST = 5       // s: True, False, None
const N_LIST = 6        // kids (tuples too)
const N_DICT = 7        // kids: key, value, key, value
const N_ATTR = 8        // a.s
const N_CALL = 9        // a(kids)
const N_KW = 10         // s=a, a keyword argument
const N_SUB = 11        // a[b]
const N_BIN = 12        // a s b
const N_NOT = 13        // not a
const N_NEG = 14        // -a
const N_AND = 15        // a and b
const N_OR = 16         // a or b
const N_CMP = 17        // a s b
const N_COND = 18       // b if a else c
const N_COMP = 19       // [a for kids(names) in b if c]
const N_UNSUPPORTED = 20 // an expression this subset does not read: Unknown
const N_SPREAD = 21      // **a, inside a dict literal
const N_DICTCOMP = 22    // {a: kids[2] for kids[0] in kids[1] if c}

const N_EXPR = 30       // a
const N_ASSIGN = 31     // a = b
const N_AUG = 32        // a s= b
const N_IF = 33         // a: kids; orelse in the node b (an N_BLOCK) or -1
const N_FOR = 34        // for a(targets list) in b: kids
const N_RETURN = 35     // a or -1
const N_PASS = 36
const N_DEL = 37        // a
const N_DEF = 38        // s(params in a: an N_LIST of N_NAME/N_KW): kids; b = 1 for a property
const N_BLOCK = 39      // kids
const N_BREAK = 40
const N_CONTINUE = 41
const N_RAISE = 42
const N_CLASS = 43      // s: kids

pub type PyNode { kind: i32, a: i32, b: i32, c: i32, s: str, kids: List[i32], line: i32 }

type PyParser { toks: List[PyTok], at: i32, nodes: List[PyNode], err: str }

impl PyParser:
    fn kind() -> i32: self.toks[self.at].kind
    fn text() -> str: self.toks[self.at].text.clone()
    fn line() -> i32: self.toks[self.at].line
    fn is_op(op: &str) -> bool: self.toks[self.at].kind == PT_OP and self.toks[self.at].text == op
    fn is_word(word: &str) -> bool: self.toks[self.at].kind == PT_NAME and self.toks[self.at].text == word

    mut fn advance():
        if self.at < self.toks.len() as i32 - 1: self.at = self.at + 1

    mut fn accept_op(op: &str) -> bool:
        if not self.is_op(op): return false
        self.advance()
        true

    mut fn accept_word(word: &str) -> bool:
        if not self.is_word(word): return false
        self.advance()
        true

    mut fn fail(what: &str):
        if self.err.len() == 0: self.err = f"line {self.line()}: {what}"

    mut fn expect_op(op: &str):
        if not self.accept_op(op): self.fail("expected '" ++ op ++ "'")

    mut fn mk(kind: i32, a: i32, b: i32, c: i32, s: &str, kids: List[i32], line: i32) -> i32:
        self.nodes.push(PyNode { kind, a, b, c, s: s.to_owned(), kids, line })
        self.nodes.len() as i32 - 1

    mut fn leaf(kind: i32, s: &str) -> i32: self.mk(kind, -1, -1, -1, s, List.new(), self.line())

    // ── Expressions ──

    mut fn expression() -> i32:
        if self.is_word("lambda"):
            // A lambda's value is a function this subset does not call.
            while self.kind() != PT_NEWLINE and self.kind() != PT_EOF and not self.is_op(")") and not self.is_op(","): self.advance()
            return self.leaf(N_UNSUPPORTED, "lambda")
        let line = self.line()
        let value = self.or_test()
        if not self.accept_word("if"): return value
        let cond = self.or_test()
        if not self.accept_word("else"):
            self.fail("expected 'else' in a conditional expression")
            return value
        let other = self.expression()
        self.mk(N_COND, cond, value, other, "", List.new(), line)

    mut fn or_test() -> i32:
        var left = self.and_test()
        while self.is_word("or"):
            let line = self.line()
            self.advance()
            let right = self.and_test()
            left = self.mk(N_OR, left, right, -1, "", List.new(), line)
        left

    mut fn and_test() -> i32:
        var left = self.not_test()
        while self.is_word("and"):
            let line = self.line()
            self.advance()
            let right = self.not_test()
            left = self.mk(N_AND, left, right, -1, "", List.new(), line)
        left

    mut fn not_test() -> i32:
        if self.is_word("not"):
            let line = self.line()
            self.advance()
            let inner = self.not_test()
            return self.mk(N_NOT, inner, -1, -1, "", List.new(), line)
        self.comparison()

    mut fn comparison() -> i32:
        var left = self.arith()
        while true:
            let line = self.line()
            var op = ""
            if self.kind() == PT_OP and (self.text() == "==" or self.text() == "!=" or self.text() == "<" or self.text() == ">" or self.text() == "<=" or self.text() == ">="):
                op = self.text()
                self.advance()
            else if self.is_word("in"):
                op = "in"
                self.advance()
            else if self.is_word("not") and self.toks[self.at + 1].kind == PT_NAME and self.toks[self.at + 1].text == "in":
                op = "not in"
                self.advance()
                self.advance()
            else if self.is_word("is"):
                self.advance()
                op = if self.accept_word("not"): "!=" else: "=="
            else: break
            let right = self.arith()
            left = self.mk(N_CMP, left, right, -1, op, List.new(), line)
        left

    mut fn arith() -> i32:
        var left = self.term()
        while self.is_op("+") or self.is_op("-") or self.is_op("|") or self.is_op("&"):
            let line = self.line()
            let op = self.text()
            self.advance()
            let right = self.term()
            left = self.mk(N_BIN, left, right, -1, op, List.new(), line)
        left

    mut fn term() -> i32:
        var left = self.unary()
        while self.is_op("*") or self.is_op("/") or self.is_op("//") or self.is_op("%"):
            let line = self.line()
            let op = self.text()
            self.advance()
            let right = self.unary()
            left = self.mk(N_BIN, left, right, -1, op, List.new(), line)
        left

    mut fn unary() -> i32:
        if self.is_op("-"):
            let line = self.line()
            self.advance()
            let inner = self.unary()
            return self.mk(N_NEG, inner, -1, -1, "", List.new(), line)
        if self.is_op("+"):
            self.advance()
            return self.unary()
        self.primary()

    // The names a `for` binds: `x` or `k, v` (parentheses allowed).
    mut fn for_targets() -> i32:
        var names: List[i32] = List.new()
        let line = self.line()
        let paren = self.accept_op("(")
        while self.kind() == PT_NAME and not self.is_word("in"):
            names.push(self.leaf(N_NAME, self.text()))
            self.advance()
            if not self.accept_op(","): break
        if paren: self.expect_op(")")
        if names.len() == 0: self.fail("expected a name after 'for'")
        self.mk(N_LIST, -1, -1, -1, "", names, line)

    // The rest of a comprehension whose element `elt` was just parsed.
    mut fn comprehension(elt: i32) -> i32:
        let line = self.line()
        self.advance()
        let targets = self.for_targets()
        if not self.accept_word("in"): self.fail("expected 'in' in a comprehension")
        let iter = self.or_test()
        var cond: i32 = -1
        if self.accept_word("if"): cond = self.or_test()
        if self.is_word("for") or self.is_word("if"):
            // A nested comprehension is outside the subset.
            while not self.is_op(")") and not self.is_op("]") and not self.is_op("}") and self.kind() != PT_EOF: self.advance()
            return self.leaf(N_UNSUPPORTED, "nested comprehension")
        let kids: List[i32] = List.new()
        kids.push(targets)
        self.mk(N_COMP, elt, iter, cond, "", kids, line)

    mut fn call_args() -> List[i32]:
        var args: List[i32] = List.new()
        while not self.is_op(")") and self.kind() != PT_EOF and self.err.len() == 0:
            if self.is_op("*") or self.is_op("**"):
                self.advance()
                let _ = self.expression()
                args.push(self.leaf(N_UNSUPPORTED, "argument unpacking"))
            else if self.kind() == PT_NAME and self.toks[self.at + 1].kind == PT_OP and self.toks[self.at + 1].text == "=":
                let name = self.text()
                let line = self.line()
                self.advance()
                self.advance()
                let value = self.expression()
                args.push(self.mk(N_KW, value, -1, -1, name, List.new(), line))
            else:
                let value = self.expression()
                if self.is_word("for"): args.push(self.comprehension(value))
                else: args.push(value)
            if not self.accept_op(","): break
        self.expect_op(")")
        args

    mut fn primary() -> i32:
        var node = self.atom()
        while self.err.len() == 0:
            let line = self.line()
            if self.accept_op("."):
                let name = self.text()
                if self.kind() != PT_NAME:
                    self.fail("expected an attribute name")
                    break
                self.advance()
                node = self.mk(N_ATTR, node, -1, -1, name, List.new(), line)
            else if self.accept_op("("):
                let args = self.call_args()
                node = self.mk(N_CALL, node, -1, -1, "", args, line)
            else if self.accept_op("["):
                if self.is_op(":"):
                    // A slice: outside the subset.
                    while not self.is_op("]") and self.kind() != PT_EOF: self.advance()
                    self.expect_op("]")
                    node = self.leaf(N_UNSUPPORTED, "slice")
                    continue
                let index = self.expression()
                if self.is_op(":"):
                    while not self.is_op("]") and self.kind() != PT_EOF: self.advance()
                    self.expect_op("]")
                    node = self.leaf(N_UNSUPPORTED, "slice")
                    continue
                self.expect_op("]")
                node = self.mk(N_SUB, node, index, -1, "", List.new(), line)
            else: break
        node

    mut fn atom() -> i32:
        let line = self.line()
        let k = self.kind()
        if k == PT_NAME:
            let name = self.text()
            self.advance()
            if name == "True" or name == "False" or name == "None": return self.mk(N_CONST, -1, -1, -1, name, List.new(), line)
            return self.mk(N_NAME, -1, -1, -1, name, List.new(), line)
        if k == PT_NUM:
            let text = self.text()
            self.advance()
            return self.mk(N_NUM, -1, -1, -1, text, List.new(), line)
        if k == PT_STR or self.is_op("fstr["):
            // Adjacent literals are one string.
            var parts: List[i32] = List.new()
            while self.kind() == PT_STR or self.is_op("fstr["):
                if self.kind() == PT_STR:
                    parts.push(self.leaf(N_STR, self.text()))
                    self.advance()
                    continue
                self.advance()
                while not self.is_op("]fstr") and self.kind() != PT_EOF and self.err.len() == 0:
                    if self.kind() == PT_STR:
                        parts.push(self.leaf(N_STR, self.text()))
                        self.advance()
                    else if self.accept_op("f{"):
                        parts.push(self.expression())
                        self.expect_op("f}")
                    else: self.fail("malformed f-string")
                self.expect_op("]fstr")
            if parts.len() == 1 and self.nodes[parts[0]].kind == N_STR: return parts[0]
            return self.mk(N_FSTR, -1, -1, -1, "", parts, line)
        if self.accept_op("("):
            var items: List[i32] = List.new()
            if self.accept_op(")"): return self.mk(N_LIST, -1, -1, -1, "", items, line)
            let first = self.expression()
            if self.is_word("for"):
                let comp = self.comprehension(first)
                self.expect_op(")")
                return comp
            if self.accept_op(")"): return first
            items.push(first)
            while self.accept_op(","):
                if self.is_op(")"): break
                items.push(self.expression())
            self.expect_op(")")
            return self.mk(N_LIST, -1, -1, -1, "", items, line)
        if self.accept_op("["):
            var items: List[i32] = List.new()
            if self.accept_op("]"): return self.mk(N_LIST, -1, -1, -1, "", items, line)
            let first = self.expression()
            if self.is_word("for"):
                let comp = self.comprehension(first)
                self.expect_op("]")
                return comp
            items.push(first)
            while self.accept_op(","):
                if self.is_op("]"): break
                items.push(self.expression())
            self.expect_op("]")
            return self.mk(N_LIST, -1, -1, -1, "", items, line)
        if self.accept_op("{"):
            var items: List[i32] = List.new()
            var is_dict = true
            while not self.is_op("}") and self.kind() != PT_EOF and self.err.len() == 0:
                if self.is_op("**"):
                    // `**other`: the entries of another dict, in place.
                    let spread_line = self.line()
                    self.advance()
                    let inner = self.expression()
                    let spread = self.mk(N_SPREAD, inner, -1, -1, "", List.new(), spread_line)
                    items.push(spread)
                    items.push(spread)
                else:
                    let key = self.expression()
                    if self.accept_op(":"):
                        let value = self.expression()
                        if self.is_word("for"):
                            // `{k: v for names in iterable if cond}`
                            let comp_line = self.line()
                            self.advance()
                            let targets = self.for_targets()
                            if not self.accept_word("in"): self.fail("expected 'in' in a comprehension")
                            let iter = self.or_test()
                            var cond: i32 = -1
                            if self.accept_word("if"): cond = self.or_test()
                            self.expect_op("}")
                            let kids: List[i32] = List.new()
                            kids.push(targets)
                            kids.push(iter)
                            kids.push(value)
                            return self.mk(N_DICTCOMP, key, -1, cond, "", kids, comp_line)
                        items.push(key)
                        items.push(value)
                    else:
                        // A set, or a set comprehension.
                        if self.is_word("for"):
                            while not self.is_op("}") and self.kind() != PT_EOF: self.advance()
                        is_dict = false
                if not self.accept_op(","): break
            self.expect_op("}")
            if not is_dict: return self.leaf(N_UNSUPPORTED, "set or dict unpacking")
            return self.mk(N_DICT, -1, -1, -1, "", items, line)
        if self.accept_op("..."): return self.leaf(N_UNSUPPORTED, "...")
        self.fail("unexpected '" ++ self.text() ++ "'")
        self.advance()
        self.leaf(N_UNSUPPORTED, "")

    // ── Statements ──

    // An expression list: `a`, or the tuple `a, b`.
    mut fn expression_list() -> i32:
        let line = self.line()
        let first = self.expression()
        if not self.is_op(","): return first
        var items: List[i32] = List.new()
        items.push(first)
        while self.accept_op(","):
            if self.kind() == PT_NEWLINE or self.is_op("="): break
            items.push(self.expression())
        self.mk(N_LIST, -1, -1, -1, "", items, line)

    // Skips to the end of the logical line.
    mut fn skip_line():
        while self.kind() != PT_NEWLINE and self.kind() != PT_EOF: self.advance()
        if self.kind() == PT_NEWLINE: self.advance()

    // Skips the indented block that follows, when one does.
    mut fn skip_block():
        if self.kind() != PT_INDENT: return
        var depth = 0
        while self.kind() != PT_EOF:
            if self.kind() == PT_INDENT: depth = depth + 1
            if self.kind() == PT_DEDENT:
                depth = depth - 1
                if depth == 0:
                    self.advance()
                    return
            self.advance()

    // The statements after a `:` — an indented block, or the rest of the line.
    mut fn block() -> List[i32]:
        var stmts: List[i32] = List.new()
        if self.kind() != PT_NEWLINE:
            let s = self.statement()
            if s >= 0: stmts.push(s)
            return stmts
        self.advance()
        if self.kind() != PT_INDENT:
            self.fail("expected an indented block")
            return stmts
        self.advance()
        while self.kind() != PT_DEDENT and self.kind() != PT_EOF and self.err.len() == 0:
            let s = self.statement()
            if s >= 0: stmts.push(s)
        if self.kind() == PT_DEDENT: self.advance()
        stmts

    // An `if`'s `elif`/`else` tail, as the block to run when it is false.
    mut fn orelse() -> i32:
        let line = self.line()
        if self.accept_word("elif"):
            let cond = self.expression()
            self.expect_op(":")
            let body = self.block()
            let tail = self.orelse()
            let nested = self.mk(N_IF, cond, tail, -1, "", body, line)
            let kids: List[i32] = List.new()
            kids.push(nested)
            return self.mk(N_BLOCK, -1, -1, -1, "", kids, line)
        if self.accept_word("else"):
            self.expect_op(":")
            let body = self.block()
            return self.mk(N_BLOCK, -1, -1, -1, "", body, line)
        -1

    // A `def`, whose body is parsed on its own: a method this subset cannot
    // read is recorded as unreadable (c = 1) and costs only itself.
    mut fn definition(is_property: bool) -> i32:
        let line = self.line()
        self.advance()
        let name = self.text()
        self.advance()
        var params: List[i32] = List.new()
        self.expect_op("(")
        while not self.is_op(")") and self.kind() != PT_EOF and self.err.len() == 0:
            if self.is_op("*") or self.is_op("**"): self.advance()
            let pname = self.text()
            let pline = self.line()
            self.advance()
            if self.accept_op(":"):
                let _ = self.expression()
            if self.accept_op("="):
                let default = self.expression()
                params.push(self.mk(N_KW, default, -1, -1, pname, List.new(), pline))
            else: params.push(self.mk(N_NAME, -1, -1, -1, pname, List.new(), pline))
            if not self.accept_op(","): break
        self.expect_op(")")
        if self.accept_op("->"):
            let _ = self.expression()
        self.expect_op(":")
        let header_ok = self.err.len() == 0
        let body_at: i32 = self.at
        let body = self.block()
        var unreadable: i32 = 0
        if self.err.len() > 0 and header_ok:
            // Resynchronize after the body and keep going.
            unreadable = 1
            self.at = body_at
            if self.kind() == PT_NEWLINE:
                self.advance()
                self.skip_block()
            else: self.skip_line()
        let plist = self.mk(N_LIST, -1, -1, -1, "", params, line)
        let why = if unreadable == 1: self.err.clone() else: ""
        if unreadable == 1: self.err = ""
        let node = self.mk(N_DEF, plist, if is_property: 1 else: 0, unreadable, name, if unreadable == 1: List.new() else: body, line)
        if unreadable == 1: self.nodes[node].s = name ++ "\n" ++ why
        node

    mut fn statement() -> i32:
        let line = self.line()
        if self.kind() == PT_NEWLINE:
            self.advance()
            return -1
        if self.is_op("@"):
            // Decorators: only `property` changes what the name means here.
            var is_property = false
            while self.is_op("@"):
                self.advance()
                if self.is_word("property"): is_property = true
                self.skip_line()
            if self.is_word("def"): return self.definition(is_property)
            return -1
        if self.is_word("def"): return self.definition(false)
        if self.is_word("class"):
            self.advance()
            let name = self.text()
            self.advance()
            if self.accept_op("("):
                while not self.is_op(")") and self.kind() != PT_EOF: self.advance()
                self.expect_op(")")
            self.expect_op(":")
            let body = self.block()
            return self.mk(N_CLASS, -1, -1, -1, name, body, line)
        if self.accept_word("if"):
            let cond = self.expression()
            self.expect_op(":")
            let body = self.block()
            let tail = self.orelse()
            return self.mk(N_IF, cond, tail, -1, "", body, line)
        if self.accept_word("for"):
            let targets = self.for_targets()
            if not self.accept_word("in"): self.fail("expected 'in'")
            let iter = self.expression_list()
            self.expect_op(":")
            let body = self.block()
            if self.accept_word("else"):
                self.expect_op(":")
                let _ = self.block()
            return self.mk(N_FOR, targets, iter, -1, "", body, line)
        if self.is_word("try"):
            // The body runs; handlers describe failures that do not happen here.
            self.advance()
            self.expect_op(":")
            let body = self.block()
            while self.is_word("except") or self.is_word("else") or self.is_word("finally"):
                let is_finally = self.is_word("finally")
                while not self.is_op(":") and self.kind() != PT_EOF: self.advance()
                self.expect_op(":")
                let handler = self.block()
                if is_finally:
                    for h in handler: body.push(h)
            return self.mk(N_BLOCK, -1, -1, -1, "", body, line)
        if self.is_word("with") or self.is_word("while"):
            // `with` runs its body; a `while` is outside the subset.
            let is_while = self.is_word("while")
            while not self.is_op(":") and self.kind() != PT_EOF and self.kind() != PT_NEWLINE: self.advance()
            self.expect_op(":")
            let body = self.block()
            if is_while:
                let unsupported = self.leaf(N_UNSUPPORTED, "while")
                return self.mk(N_EXPR, unsupported, -1, -1, "", List.new(), line)
            return self.mk(N_BLOCK, -1, -1, -1, "", body, line)
        if self.is_word("import") or self.is_word("from") or self.is_word("assert") or self.is_word("global") or self.is_word("nonlocal"):
            self.skip_line()
            return -1
        var node = -1
        if self.accept_word("return"):
            let value = if self.kind() == PT_NEWLINE or self.kind() == PT_EOF: -1 else: self.expression_list()
            node = self.mk(N_RETURN, value, -1, -1, "", List.new(), line)
        else if self.accept_word("pass"): node = self.mk(N_PASS, -1, -1, -1, "", List.new(), line)
        else if self.accept_word("break"): node = self.mk(N_BREAK, -1, -1, -1, "", List.new(), line)
        else if self.accept_word("continue"): node = self.mk(N_CONTINUE, -1, -1, -1, "", List.new(), line)
        else if self.accept_word("raise"):
            while self.kind() != PT_NEWLINE and self.kind() != PT_EOF: self.advance()
            node = self.mk(N_RAISE, -1, -1, -1, "", List.new(), line)
        else if self.accept_word("del"):
            let target = self.expression_list()
            node = self.mk(N_DEL, target, -1, -1, "", List.new(), line)
        else:
            let target = self.expression_list()
            if self.accept_op("="):
                var value = self.expression_list()
                // `a = b = c` assigns the last value to the first target.
                while self.accept_op("="): value = self.expression_list()
                node = self.mk(N_ASSIGN, target, value, -1, "", List.new(), line)
            else if self.is_op("+=") or self.is_op("-=") or self.is_op("*=") or self.is_op("|="):
                let op = self.text().slice(0, 1).to_owned()
                self.advance()
                let value = self.expression_list()
                node = self.mk(N_AUG, target, value, -1, op, List.new(), line)
            else if self.accept_op(":"):
                // An annotation, with or without a value.
                let _ = self.expression()
                if self.accept_op("="):
                    let value = self.expression_list()
                    node = self.mk(N_ASSIGN, target, value, -1, "", List.new(), line)
            else: node = self.mk(N_EXPR, target, -1, -1, "", List.new(), line)
        if self.accept_op(";"): return node
        if self.kind() == PT_NEWLINE: self.advance()
        else if self.kind() != PT_EOF and self.kind() != PT_DEDENT: self.fail("unexpected '" ++ self.text() ++ "'")
        node

// The recipe as a tree: the nodes, the top-level statements, and what could
// not be read ("" when all of it was).
pub type PyModule { nodes: List[PyNode], top: List[i32], problem: str }

pub fn py_parse(src: &str) -> PyModule:
    var p = PyParser { toks: py_lex(src), at: 0, nodes: List.new(), err: "" }
    var top: List[i32] = List.new()
    while p.kind() != PT_EOF and p.err.len() == 0:
        if p.kind() == PT_INDENT or p.kind() == PT_DEDENT:
            p.advance()
            continue
        let s = p.statement()
        if s >= 0: top.push(s)
    PyModule { nodes: move p.nodes, top, problem: move p.err }

// ── Values ───────────────────────────────────────────────────────────

const V_UNKNOWN = 0
const V_NONE = 1
const V_BOOL = 2        // n
const V_INT = 3         // n
const V_STR = 4         // s
const V_LIST = 5        // n: list arena index
const V_DICT = 6        // n: dict arena index
const V_OBJ = 7         // n: object arena index
const V_FUNC = 8        // n: N_DEF node
const V_BOUND = 9       // s: method name; n: receiver arena index
const V_SINK = 10       // something whose contents nothing here reads
const V_VER = 11        // s: a version, compared by component
const V_OPT = 12        // s: an option's value, as Conan spells it
const V_NAMED = 13      // s: a name from outside the recipe (`os.path.join`)

pub type PyVal { k: i32, n: i64, s: str }

fn pv(k: i32, n: i64, s: &str): PyVal { k, n, s: s.to_owned() }
fn pv_copy(v: &PyVal): PyVal { k: v.k, n: v.n, s: v.s.clone() }
fn pv_unknown(): pv(V_UNKNOWN, 0, "")
fn pv_none(): pv(V_NONE, 0, "")
fn pv_bool(b: bool): pv(V_BOOL, if b: 1 else: 0, "")
fn pv_str(s: &str): pv(V_STR, 0, s)
fn pv_sink(): pv(V_SINK, 0, "")

type PyObj { cls: str, names: List[str], vals: List[PyVal] }

// A list, a dict's keys or values, a frame's names or values: each held in
// an arena and named by its index, since a Python list is shared by
// everything that holds it.
type PyList { items: List[PyVal] }
type PyNames { items: List[str] }

// What a recipe is evaluated against: the platform and compiler of the
// binary (its conaninfo, or this toolchain for a package built here), the
// package's version and directory, and its options as `name=value` when the
// binary states them (`options_known`); otherwise the recipe's defaults are
// taken and its `config_options` and `configure` run over them.
pub type RecipeEnv { os: str, arch: str, compiler: str, compiler_version: str, build_type: str, version: str, package_folder: str, source_folder: str, options: List[str], options_known: bool }

// One `cpp_info`: the package's own, or a component's.
pub type RecipeComponent { name: str, libs: List[str], system_libs: List[str], frameworks: List[str], libdirs: List[str], includedirs: List[str], defines: List[str], exelinkflags: List[str], requires: List[str] }

// What `package_info` said: the package's own cpp_info, its components in
// the order the recipe names them, and every decision that could not be made
// (`notes`). `ok` is false when the recipe or the method could not be read
// at all (`problem`).
pub type RecipePackageInfo { ok: bool, problem: str, notes: List[str], root: RecipeComponent, components: List[RecipeComponent] }

const PY_NORMAL = 0
const PY_RETURN = 1
const PY_BREAK = 2
const PY_CONTINUE = 3

const PY_STEP_LIMIT = 400000

type PyInterp { nodes: List[PyNode], lists: List[PyList], dkeys: List[PyList], dvals: List[PyList], objs: List[PyObj], recv: List[PyVal], frame_names: List[PyNames], frame_vals: List[PyList], method_names: List[str], method_nodes: List[i32], attr_names: List[str], attr_vals: List[PyVal], func_names: List[str], func_nodes: List[i32], self_obj: i32, env: RecipeEnv, notes: List[str], ret: PyVal, steps: i32, depth: i32, problem: str, reqs: List[str], tool_reqs: List[str], toolchains: List[i32] }

// Numeric order of two versions, component by component; a missing
// component is 0, and a component that is not a number orders as text.
pub fn py_version_order(a: &str, b: &str) -> i32:
    let pa = a.split(".")
    let pb = b.split(".")
    let n = if pa.len() > pb.len(): pa.len() as i32 else: pb.len() as i32
    for i in 0..n:
        let x: &str = if i < pa.len() as i32: &pa[i] else: "0"
        let y: &str = if i < pb.len() as i32: &pb[i] else: "0"
        var xn = 0
        var yn = 0
        var xd = 0
        var yd = 0
        while xd < x.len() as i32 and py_is_digit(x[xd]):
            xn = xn * 10 + (x[xd] - '0') as i32
            xd = xd + 1
        while yd < y.len() as i32 and py_is_digit(y[yd]):
            yn = yn * 10 + (y[yd] - '0') as i32
            yd = yd + 1
        if xn != yn: return if xn < yn: -1 else: 1
        let xr = x.slice(xd, x.len())
        let yr = y.slice(yd, y.len())
        if xr != yr: return if xr < yr: -1 else: 1
    0

fn py_parse_int(text: &str) -> (bool, i64):
    var n: i64 = 0
    if text.len() == 0: return (false, 0)
    for i in 0..text.len() as i32:
        if not py_is_digit(text[i]): return (false, 0)
        n = n * 10 + (text[i] - '0') as i64
    (true, n)

// An option's value as Conan spells it.
fn py_option_text(v: &PyVal) -> str:
    if v.k == V_BOOL: return if v.n != 0: "True" else: "False"
    if v.k == V_NONE: return "None"
    if v.k == V_INT: return f"{v.n}"
    v.s.clone()

impl PyInterp:
    // ── Arenas ──

    mut fn new_list(items: List[PyVal]) -> PyVal:
        self.lists.push(PyList { items })
        pv(V_LIST, self.lists.len() as i64 - 1, "")

    mut fn new_str_list(items: &List[str]) -> PyVal:
        var out: List[PyVal] = List.new()
        for s in items: out.push(pv_str(s))
        self.new_list(move out)

    mut fn new_dict() -> PyVal:
        self.dkeys.push(PyList { items: List.new() })
        self.dvals.push(PyList { items: List.new() })
        pv(V_DICT, self.dkeys.len() as i64 - 1, "")

    mut fn new_obj(cls: &str) -> i32:
        self.objs.push(PyObj { cls: cls.to_owned(), names: List.new(), vals: List.new() })
        self.objs.len() as i32 - 1

    fn obj_find(obj: i32, name: &str) -> i32:
        for i in 0..self.objs[obj].names.len() as i32:
            if self.objs[obj].names[i] == name: return i
        -1

    mut fn obj_set(obj: i32, name: &str, value: PyVal):
        let at = self.obj_find(obj, name)
        if at >= 0:
            self.objs[obj].vals[at] = value
            return
        self.objs[obj].names.push(name.to_owned())
        self.objs[obj].vals.push(value)

    mut fn obj_remove(obj: i32, name: &str):
        let at = self.obj_find(obj, name)
        if at < 0: return
        var names: List[str] = List.new()
        var vals: List[PyVal] = List.new()
        for i in 0..self.objs[obj].names.len() as i32:
            if i == at: continue
            names.push(self.objs[obj].names[i].clone())
            vals.push(pv_copy(&self.objs[obj].vals[i]))
        self.objs[obj].names = names
        self.objs[obj].vals = vals

    mut fn bound(receiver: &PyVal, name: &str) -> PyVal:
        self.recv.push(pv_copy(receiver))
        pv(V_BOUND, self.recv.len() as i64 - 1, name)

    mut fn note(line: i32, what: &str):
        let text = f"line {line}: {what}"
        for n in self.notes:
            if n == text: return
        self.notes.push(text)

    // ── Truth, equality, order ──

    // A setting object stands for its value.
    fn plain(v: &PyVal) -> PyVal:
        if v.k == V_OBJ and self.objs[v.n as i32].cls == "setting":
            let at = self.obj_find(v.n as i32, "value")
            if at >= 0: return pv_copy(&self.objs[v.n as i32].vals[at])
        pv_copy(v)

    // 1 true, 0 false, -1 not known.
    fn truth(v0: &PyVal) -> i32:
        let v = self.plain(v0)
        if v.k == V_UNKNOWN or v.k == V_SINK or v.k == V_NAMED: return -1
        if v.k == V_NONE: return 0
        if v.k == V_BOOL or v.k == V_INT: return if v.n != 0: 1 else: 0
        if v.k == V_STR or v.k == V_VER: return if v.s.len() > 0: 1 else: 0
        if v.k == V_OPT: return if v.s == "False" or v.s == "None" or v.s == "" or v.s == "0": 0 else: 1
        if v.k == V_LIST: return if self.lists[v.n as i32].items.len() > 0: 1 else: 0
        if v.k == V_DICT: return if self.dkeys[v.n as i32].items.len() > 0: 1 else: 0
        1

    // 1 equal, 0 not, -1 not known.
    fn equal(a0: &PyVal, b0: &PyVal) -> i32:
        let a = self.plain(a0)
        let b = self.plain(b0)
        if a.k == V_UNKNOWN or b.k == V_UNKNOWN or a.k == V_SINK or b.k == V_SINK or a.k == V_NAMED or b.k == V_NAMED: return -1
        if a.k == V_OPT or b.k == V_OPT:
            let x = py_option_text(&a)
            let y = py_option_text(&b)
            return if x == y: 1 else: 0
        if a.k == V_VER or b.k == V_VER:
            if (a.k != V_VER and a.k != V_STR and a.k != V_INT) or (b.k != V_VER and b.k != V_STR and b.k != V_INT): return 0
            return if py_version_order(py_option_text(&a), py_option_text(&b)) == 0: 1 else: 0
        if a.k != b.k: return 0
        if a.k == V_NONE: return 1
        if a.k == V_BOOL or a.k == V_INT: return if a.n == b.n: 1 else: 0
        if a.k == V_STR: return if a.s == b.s: 1 else: 0
        if a.k == V_LIST:
            let n = self.lists[a.n as i32].items.len() as i32
            if n != self.lists[b.n as i32].items.len() as i32: return 0
            for i in 0..n:
                let e = self.equal(&self.lists[a.n as i32].items[i], &self.lists[b.n as i32].items[i])
                if e != 1: return e
            return 1
        if a.n == b.n: 1 else: 0

    // -1, 0, 1, or 2 when the two do not order.
    fn order(a0: &PyVal, b0: &PyVal) -> i32:
        let a = self.plain(a0)
        let b = self.plain(b0)
        if a.k == V_VER or b.k == V_VER:
            if (a.k != V_VER and a.k != V_STR and a.k != V_INT) or (b.k != V_VER and b.k != V_STR and b.k != V_INT): return 2
            return py_version_order(py_option_text(&a), py_option_text(&b))
        if a.k == V_INT and b.k == V_INT: return if a.n < b.n: -1 else: if a.n > b.n: 1 else: 0
        if (a.k == V_STR or a.k == V_OPT) and (b.k == V_STR or b.k == V_OPT): return if a.s < b.s: -1 else: if a.s > b.s: 1 else: 0
        2

    // 1 contained, 0 not, -1 not known.
    fn contains(item0: &PyVal, container0: &PyVal) -> i32:
        let item = self.plain(item0)
        let container = self.plain(container0)
        if container.k == V_LIST:
            var unknown = false
            for i in 0..self.lists[container.n as i32].items.len() as i32:
                let e = self.equal(&item, &self.lists[container.n as i32].items[i])
                if e == 1: return 1
                if e < 0: unknown = true
            return if unknown: -1 else: 0
        if container.k == V_DICT:
            for i in 0..self.dkeys[container.n as i32].items.len() as i32:
                if self.equal(&item, &self.dkeys[container.n as i32].items[i]) == 1: return 1
            return if item.k == V_UNKNOWN: -1 else: 0
        if (container.k == V_STR or container.k == V_OPT) and (item.k == V_STR or item.k == V_OPT): return if container.s.contains(item.s): 1 else: 0
        -1

    // The text `str(v)` gives, or Unknown.
    fn to_text(v0: &PyVal) -> PyVal:
        let v = self.plain(v0)
        if v.k == V_STR or v.k == V_VER or v.k == V_OPT: return pv_str(v.s)
        if v.k == V_BOOL or v.k == V_NONE or v.k == V_INT: return pv_str(py_option_text(&v))
        pv_unknown()

    // ── Names ──

    fn lookup(name: &str) -> PyVal:
        let top = self.frame_names.len() as i32 - 1
        for i in 0..self.frame_names[top].items.len() as i32:
            if self.frame_names[top].items[i] == name: return pv_copy(&self.frame_vals[top].items[i])
        if top > 0:
            for i in 0..self.frame_names[0].items.len() as i32:
                if self.frame_names[0].items[i] == name: return pv_copy(&self.frame_vals[0].items[i])
        for i in 0..self.func_names.len() as i32:
            if self.func_names[i] == name: return pv(V_FUNC, self.func_nodes[i] as i64, name)
        if name == "conan_version": return pv(V_VER, 0, "2.0")
        // A name the recipe imports: what it is shows when it is used.
        pv(V_NAMED, 0, name)

    mut fn bind(name: &str, value: PyVal):
        let top = self.frame_names.len() as i32 - 1
        for i in 0..self.frame_names[top].items.len() as i32:
            if self.frame_names[top].items[i] == name:
                self.frame_vals[top].items[i] = value
                return
        self.frame_names[top].items.push(name.to_owned())
        self.frame_vals[top].items.push(value)

    // ── The recipe's objects ──

    // The list a cpp_info attribute holds, created on first use.
    mut fn cppinfo_attr(obj: i32, name: &str) -> PyVal:
        let at = self.obj_find(obj, name)
        if at >= 0: return pv_copy(&self.objs[obj].vals[at])
        if name == "components":
            let comps = self.new_obj("components")
            self.obj_set(obj, name, pv(V_OBJ, comps as i64, ""))
            return pv(V_OBJ, comps as i64, "")
        if name == "libs" or name == "system_libs" or name == "frameworks" or name == "defines" or name == "cflags" or name == "cxxflags" or name == "sharedlinkflags" or name == "exelinkflags" or name == "requires" or name == "objects" or name == "libdirs" or name == "includedirs" or name == "bindirs" or name == "resdirs" or name == "srcdirs" or name == "builddirs" or name == "frameworkdirs":
            var items: List[PyVal] = List.new()
            if name == "libdirs": items.push(pv_str("lib"))
            if name == "includedirs": items.push(pv_str("include"))
            if name == "bindirs": items.push(pv_str("bin"))
            let list = self.new_list(move items)
            self.obj_set(obj, name, pv_copy(&list))
            return list
        if name == "set_property" or name == "get_property": return self.bound(&pv(V_OBJ, obj as i64, ""), name)
        // names, filenames, build_modules, version and the rest: not link facts.
        pv_sink()

    // A recipe method or property, looked up by name on `self`.
    mut fn self_attr(name: &str, line: i32) -> PyVal:
        let at = self.obj_find(self.self_obj, name)
        if at >= 0: return pv_copy(&self.objs[self.self_obj].vals[at])
        if name == "requires" or name == "tool_requires" or name == "build_requires" or name == "test_requires":
            // `self.requires("zlib/1.3")`, unless the class states `requires = …`.
            var stated = false
            for i in 0..self.attr_names.len() as i32:
                if self.attr_names[i] == name: stated = true
            if not stated: return self.bound(&pv(V_OBJ, self.self_obj as i64, ""), name)
        for i in 0..self.method_names.len() as i32:
            if self.method_names[i] != name: continue
            let node: i32 = self.method_nodes[i]
            if self.nodes[node].b == 1: return self.call_def(node, List.new(), line)
            return pv(V_FUNC, node as i64, name)
        for i in 0..self.attr_names.len() as i32:
            if self.attr_names[i] == name: return pv_copy(&self.attr_vals[i])
        if name == "output" or name == "conf" or name == "runenv_info" or name == "buildenv_info" or name == "env_info" or name == "user_info" or name == "conf_info" or name == "info" or name == "cpp" or name == "layouts" or name == "folders" or name == "win_bash" or name == "python_requires": return pv_sink()
        pv_unknown()

    mut fn attribute(target: &PyVal, name: &str, line: i32) -> PyVal:
        if target.k == V_SINK: return pv_sink()
        if target.k == V_NAMED: return pv(V_NAMED, 0, target.s ++ "." ++ name)
        if target.k == V_VER:
            let index = if name == "major": 0 else: if name == "minor": 1 else: if name == "patch": 2 else: -1
            if index < 0: return pv_unknown()
            let parts = target.s.split(".")
            if index >= parts.len() as i32: return pv(V_VER, 0, "0")
            return pv(V_VER, 0, parts[index])
        if target.k == V_STR or target.k == V_LIST or target.k == V_DICT or target.k == V_OPT: return self.bound(target, name)
        if target.k != V_OBJ: return pv_unknown()
        let obj = target.n as i32
        let cls = self.objs[obj].cls.clone()
        if cls == "self": return self.self_attr(name, line)
        if cls == "cppinfo": return self.cppinfo_attr(obj, name)
        if cls == "options":
            if name == "get_safe" or name == "rm_safe" or name == "items" or name == "values" or name == "update": return self.bound(target, name)
            let at = self.obj_find(obj, name)
            if at >= 0: return pv_copy(&self.objs[obj].vals[at])
            // Conan raises on an option the package does not have.
            self.note(line, "the recipe reads option '" ++ name ++ "', which this package does not have")
            return pv_unknown()
        if cls == "settings" or cls == "setting":
            if name == "get_safe" or name == "rm_safe": return self.bound(target, name)
            let at = self.obj_find(obj, name)
            if at >= 0: return pv_copy(&self.objs[obj].vals[at])
            return pv_none()
        if cls == "toolchain" and self.obj_find(obj, name) < 0: return pv_sink()
        let at = self.obj_find(obj, name)
        if at >= 0: return pv_copy(&self.objs[obj].vals[at])
        pv_unknown()

    mut fn subscript(target: &PyVal, index: &PyVal) -> PyVal:
        if target.k == V_SINK: return pv_sink()
        if target.k == V_OBJ and self.objs[target.n as i32].cls == "components":
            if index.k != V_STR: return pv_unknown()
            let obj = target.n as i32
            let at = self.obj_find(obj, index.s)
            if at >= 0: return pv_copy(&self.objs[obj].vals[at])
            let comp = self.new_obj("cppinfo")
            self.obj_set(obj, index.s, pv(V_OBJ, comp as i64, ""))
            return pv(V_OBJ, comp as i64, "")
        if target.k == V_OBJ and self.objs[target.n as i32].cls == "options": return pv_sink()
        if target.k == V_LIST and index.k == V_INT:
            let n = self.lists[target.n as i32].items.len() as i64
            let i = if index.n < 0: n + index.n else: index.n
            if i < 0 or i >= n: return pv_unknown()
            return pv_copy(&self.lists[target.n as i32].items[i as i32])
        if target.k == V_DICT:
            for i in 0..self.dkeys[target.n as i32].items.len() as i32:
                if self.equal(index, &self.dkeys[target.n as i32].items[i]) == 1: return pv_copy(&self.dvals[target.n as i32].items[i])
        pv_unknown()

    // ── Calls ──

    mut fn dotted_setting(root: &PyVal, path: &str) -> PyVal:
        var cur = pv_copy(root)
        for part in path.split("."):
            if cur.k != V_OBJ: return pv_none()
            let at = self.obj_find(cur.n as i32, part)
            if at < 0: return pv_none()
            cur = pv_copy(&self.objs[cur.n as i32].vals[at])
        self.plain(&cur)

    mut fn call_method(receiver: &PyVal, name: &str, args: &List[PyVal], line: i32) -> PyVal:
        let arg0 = if args.len() > 0: pv_copy(&args[0]) else: pv_unknown()
        if receiver.k == V_LIST:
            let id = receiver.n as i32
            if name == "append":
                self.lists[id].items.push(arg0)
                return pv_none()
            if name == "extend":
                if arg0.k != V_LIST:
                    self.note(line, "a list is extended by something that could not be evaluated")
                    return pv_none()
                var items: List[PyVal] = List.new()
                for i in 0..self.lists[arg0.n as i32].items.len() as i32: items.push(pv_copy(&self.lists[arg0.n as i32].items[i]))
                for item in items: self.lists[id].items.push(pv_copy(item))
                return pv_none()
            if name == "insert" and args.len() > 1:
                var items: List[PyVal] = List.new()
                let n = self.lists[id].items.len() as i32
                let at = if arg0.k == V_INT and arg0.n >= 0 and arg0.n as i32 <= n: arg0.n as i32 else: n
                for i in 0..n:
                    if i == at: items.push(pv_copy(&args[1]))
                    items.push(pv_copy(&self.lists[id].items[i]))
                if at >= n: items.push(pv_copy(&args[1]))
                self.lists[id].items = items
                return pv_none()
            if name == "remove":
                var items: List[PyVal] = List.new()
                var removed = false
                for i in 0..self.lists[id].items.len() as i32:
                    if not removed and self.equal(&arg0, &self.lists[id].items[i]) == 1:
                        removed = true
                        continue
                    items.push(pv_copy(&self.lists[id].items[i]))
                self.lists[id].items = items
                return pv_none()
            if name == "copy":
                var items: List[PyVal] = List.new()
                for i in 0..self.lists[id].items.len() as i32: items.push(pv_copy(&self.lists[id].items[i]))
                return self.new_list(move items)
            return pv_unknown()
        if receiver.k == V_STR or receiver.k == V_OPT:
            let s = receiver.s.clone()
            if name == "startswith" and arg0.k == V_STR: return pv_bool(s.starts_with(arg0.s))
            if name == "endswith" and arg0.k == V_STR: return pv_bool(s.ends_with(arg0.s))
            if name == "lower": return pv_str(s.to_lower())
            if name == "upper": return pv_str(s.to_upper())
            if name == "strip" and args.len() == 0: return pv_str(s.trim())
            if name == "replace" and args.len() > 1 and arg0.k == V_STR and args[1].k == V_STR: return pv_str(s.replace(arg0.s, args[1].s))
            if name == "split" and arg0.k == V_STR:
                var items: List[PyVal] = List.new()
                for part in s.split(arg0.s): items.push(pv_str(part))
                return self.new_list(move items)
            if name == "format":
                // `{}` takes the next argument, `{N}` the Nth.
                var out = ""
                var next = 0
                var i = 0
                let n = s.len() as i32
                while i < n:
                    if s[i] == '{' and i + 1 < n and s[i + 1] == '{':
                        out = out ++ "{"
                        i = i + 2
                    else if s[i] == '}' and i + 1 < n and s[i + 1] == '}':
                        out = out ++ "}"
                        i = i + 2
                    else if s[i] == '{':
                        let close = s.slice(i, n).find("}") as i32
                        if close < 0: return pv_unknown()
                        let field = s.slice(i + 1, i + close)
                        var index = next
                        if field.len() == 0: next = next + 1
                        else:
                            let (ok, wanted) = py_parse_int(field)
                            if not ok: return pv_unknown()
                            index = wanted as i32
                        if index >= args.len() as i32: return pv_unknown()
                        let part = self.to_text(&args[index])
                        if part.k != V_STR: return pv_unknown()
                        out = out ++ part.s
                        i = i + close + 1
                    else:
                        out = out ++ s.slice(i, i + 1)
                        i = i + 1
                return pv_str(out)
            if name == "join" and arg0.k == V_LIST:
                var out = ""
                for i in 0..self.lists[arg0.n as i32].items.len() as i32:
                    let part = self.to_text(&self.lists[arg0.n as i32].items[i])
                    if part.k != V_STR: return pv_unknown()
                    out = out ++ (if i > 0: s.clone() else: "") ++ part.s
                return pv_str(out)
            return pv_unknown()
        if receiver.k == V_DICT:
            let id = receiver.n as i32
            if name == "get":
                for i in 0..self.dkeys[id].items.len() as i32:
                    if self.equal(&arg0, &self.dkeys[id].items[i]) == 1: return pv_copy(&self.dvals[id].items[i])
                return if args.len() > 1: pv_copy(&args[1]) else: pv_none()
            if name == "keys" or name == "values" or name == "items":
                var items: List[PyVal] = List.new()
                for i in 0..self.dkeys[id].items.len() as i32:
                    if name == "keys": items.push(pv_copy(&self.dkeys[id].items[i]))
                    else if name == "values": items.push(pv_copy(&self.dvals[id].items[i]))
                    else:
                        var pair: List[PyVal] = List.new()
                        pair.push(pv_copy(&self.dkeys[id].items[i]))
                        pair.push(pv_copy(&self.dvals[id].items[i]))
                        items.push(self.new_list(move pair))
                return self.new_list(move items)
            return pv_unknown()
        if receiver.k != V_OBJ: return pv_unknown()
        let obj = receiver.n as i32
        let cls = self.objs[obj].cls.clone()
        if cls == "cppinfo": return if name == "set_property": pv_none() else: pv_unknown()
        if cls == "self":
            if name == "test_requires": return pv_none()
            if name == "requires" or name == "tool_requires" or name == "build_requires":
                let reference = self.to_text(&arg0)
                if reference.k != V_STR:
                    self.note(line, "a requirement could not be evaluated")
                    return pv_none()
                if name == "requires": self.reqs.push(reference.s.clone())
                else: self.tool_reqs.push(reference.s.clone())
                return pv_none()
            return pv_unknown()
        if cls == "options":
            if name == "get_safe" and arg0.k == V_STR:
                let at = self.obj_find(obj, arg0.s)
                if at >= 0: return pv_copy(&self.objs[obj].vals[at])
                return if args.len() > 1: pv_copy(&args[1]) else: pv_none()
            if name == "rm_safe" and arg0.k == V_STR:
                self.obj_remove(obj, arg0.s)
                return pv_none()
            return pv_unknown()
        if cls == "settings" or cls == "setting":
            if name == "get_safe" and arg0.k == V_STR:
                let found = self.dotted_setting(receiver, arg0.s)
                return if found.k == V_NONE and args.len() > 1: pv_copy(&args[1]) else: found
            if name == "rm_safe": return pv_none()
        pv_unknown()

    // A function the recipe imports, by the name it calls it under.
    mut fn call_named(name: &str, args: &List[PyVal], line: i32) -> PyVal:
        let arg0 = if args.len() > 0: self.plain(&args[0]) else: pv_unknown()
        let os = self.env.os.clone()
        if name == "is_apple_os": return pv_bool(os == "Macos" or os == "iOS" or os == "watchOS" or os == "tvOS" or os == "visionOS")
        if name == "is_msvc": return pv_bool(self.env.compiler == "msvc" or self.env.compiler == "Visual Studio")
        if name == "is_msvc_static_runtime": return if self.env.compiler == "msvc" or self.env.compiler == "Visual Studio": pv_unknown() else: pv_bool(false)
        if name == "cross_building": return pv_bool(false)
        if name == "can_run": return pv_bool(true)
        if name == "Version":
            let text = self.to_text(&arg0)
            return if text.k == V_STR: pv(V_VER, 0, text.s) else: pv_unknown()
        if name == "str": return self.to_text(&arg0)
        if name == "bool":
            let t = self.truth(&arg0)
            return if t < 0: pv_unknown() else: pv_bool(t == 1)
        if name == "int":
            let text = self.to_text(&arg0)
            if text.k != V_STR: return pv_unknown()
            let (ok, n) = py_parse_int(text.s)
            return if ok: pv(V_INT, n, "") else: pv_unknown()
        if name == "len":
            if arg0.k == V_LIST: return pv(V_INT, self.lists[arg0.n as i32].items.len() as i64, "")
            if arg0.k == V_STR: return pv(V_INT, arg0.s.len() as i64, "")
            if arg0.k == V_DICT: return pv(V_INT, self.dkeys[arg0.n as i32].items.len() as i64, "")
            return pv_unknown()
        if name == "list" or name == "tuple" or name == "sorted" or name == "set":
            if args.len() == 0: return self.new_list(List.new())
            if arg0.k != V_LIST: return pv_unknown()
            return self.call_method(&arg0, "copy", &List.new(), line)
        if name == "any" or name == "all":
            if arg0.k != V_LIST: return pv_unknown()
            var unknown = false
            for i in 0..self.lists[arg0.n as i32].items.len() as i32:
                let t = self.truth(&self.lists[arg0.n as i32].items[i])
                if t < 0: unknown = true
                else if name == "any" and t == 1: return pv_bool(true)
                else if name == "all" and t == 0: return pv_bool(false)
            return if unknown: pv_unknown() else: pv_bool(name == "all")
        if name == "os.path.join":
            var out = ""
            for i in 0..args.len() as i32:
                let part = self.to_text(&args[i])
                if part.k != V_STR: return pv_unknown()
                if part.s.len() == 0: continue
                out = if out.len() == 0 or part.s.starts_with("/"): part.s.clone() else: out ++ "/" ++ part.s
            return pv_str(out)
        if name == "os.path.basename" and arg0.k == V_STR:
            let parts = arg0.s.split("/")
            return pv_str(parts[parts.len() as i32 - 1])
        if name == "textwrap.dedent": return arg0
        if name == "print" or name == "check_min_cppstd" or name == "check_max_cppstd" or name == "check_min_cstd": return pv_none()
        // PkgConfig, self.dependencies, tools this model does not carry.
        if name == "collect_libs":
            // Conan's helper: the libraries the package holds in its library
            // directories, by the names a linker is given.
            let folder = self.env.package_folder.clone()
            if folder.len() == 0: return pv_unknown()
            var names: List[str] = List.new()
            for dir in ["lib"]:
                let base = folder ++ "/" ++ dir ++ "/"
                for path in runtime_list_files(folder ++ "/" ++ dir).split("\n"):
                    if not path.starts_with(base): continue
                    let file = path.slice(base.len(), path.len())
                    if file.contains("/"): continue
                    var stem = ""
                    if file.ends_with(".lib"): stem = file.slice(0, file.len() - 4).to_owned()
                    else if file.starts_with("lib"):
                        for ext in [".a", ".so", ".dylib"]:
                            let at = file.find(ext)
                            if at > 3 and stem.len() == 0: stem = file.slice(3, at).to_owned()
                    if stem.len() == 0: continue
                    var seen = false
                    for n in names:
                        if n == stem: seen = true
                    if not seen: names.push(stem)
            return self.new_str_list(&names)
        if name == "CMakeToolchain":
            // What `generate` sets on it is what the build is configured with.
            let tc = self.new_obj("toolchain")
            let variables = self.new_dict()
            let cache = self.new_dict()
            self.obj_set(tc, "variables", variables)
            self.obj_set(tc, "cache_variables", cache)
            self.toolchains.push(tc)
            return pv(V_OBJ, tc as i64, "")
        if name == "PkgConfig" or name == "VirtualBuildEnv" or name == "VirtualRunEnv" or name == "Environment": return pv_sink()
        pv_unknown()

    mut fn call_def(node: i32, args: List[PyVal], line: i32) -> PyVal:
        if self.nodes[node].c == 1:
            self.note(line, "the recipe's '" ++ self.nodes[node].s.split("\n")[0] ++ "' could not be read (" ++ self.nodes[node].s.split("\n")[1] ++ ")")
            return pv_unknown()
        if self.depth > 40:
            self.note(line, "the recipe recurses too deeply")
            return pv_unknown()
        var names: List[str] = List.new()
        var vals: List[PyVal] = List.new()
        let params = self.nodes[node].a
        var next = 0
        for pi in 0..self.nodes[params].kids.len() as i32:
            let p: i32 = self.nodes[params].kids[pi]
            let pname = self.nodes[p].s.clone()
            if pi == 0 and pname == "self":
                names.push(pname)
                vals.push(pv(V_OBJ, self.self_obj as i64, ""))
                continue
            names.push(pname)
            if next < args.len() as i32:
                vals.push(pv_copy(&args[next]))
                next = next + 1
            else if self.nodes[p].kind == N_KW: vals.push(self.eval(self.nodes[p].a))
            else: vals.push(pv_unknown())
        self.frame_names.push(PyNames { items: names })
        self.frame_vals.push(PyList { items: vals })
        self.depth = self.depth + 1
        self.ret = pv_none()
        let _ = self.exec_block(node)
        self.depth = self.depth - 1
        let _n = self.frame_names.pop()
        let _v = self.frame_vals.pop()
        let out = pv_copy(&self.ret)
        self.ret = pv_none()
        out

    mut fn call(node: i32) -> PyVal:
        let line = self.nodes[node].line
        let callee = self.eval(self.nodes[node].a)
        var args: List[PyVal] = List.new()
        for i in 0..self.nodes[node].kids.len() as i32:
            let arg: i32 = self.nodes[node].kids[i]
            // A keyword argument is passed by position after the others;
            // the functions modeled here take theirs that way.
            if self.nodes[arg].kind == N_KW: args.push(self.eval(self.nodes[arg].a))
            else: args.push(self.eval(arg))
        if callee.k == V_SINK: return pv_sink()
        if callee.k == V_FUNC: return self.call_def(callee.n as i32, move args, line)
        if callee.k == V_NAMED: return self.call_named(callee.s, &args, line)
        if callee.k == V_BOUND:
            let receiver = pv_copy(&self.recv[callee.n as i32])
            return self.call_method(&receiver, callee.s, &args, line)
        pv_unknown()

    // ── Expressions ──

    mut fn eval(node: i32) -> PyVal:
        self.steps = self.steps + 1
        if self.steps > PY_STEP_LIMIT:
            if self.problem.len() == 0: self.problem = "the recipe did not finish evaluating"
            return pv_unknown()
        let kind = self.nodes[node].kind
        let line = self.nodes[node].line
        if kind == N_NAME: return self.lookup(self.nodes[node].s)
        if kind == N_STR: return pv_str(self.nodes[node].s)
        if kind == N_NUM:
            let (ok, n) = py_parse_int(self.nodes[node].s)
            return if ok: pv(V_INT, n, "") else: pv_str(self.nodes[node].s)
        if kind == N_CONST:
            let s = self.nodes[node].s.clone()
            return if s == "None": pv_none() else: pv_bool(s == "True")
        if kind == N_FSTR:
            var out = ""
            for i in 0..self.nodes[node].kids.len() as i32:
                let part = self.to_text(&self.eval(self.nodes[node].kids[i]))
                if part.k != V_STR: return pv_unknown()
                out = out ++ part.s
            return pv_str(out)
        if kind == N_LIST:
            var items: List[PyVal] = List.new()
            for i in 0..self.nodes[node].kids.len() as i32: items.push(self.eval(self.nodes[node].kids[i]))
            return self.new_list(move items)
        if kind == N_DICT:
            let dict = self.new_dict()
            var i = 0
            while i + 1 < self.nodes[node].kids.len() as i32:
                let key_node: i32 = self.nodes[node].kids[i]
                if self.nodes[key_node].kind == N_SPREAD:
                    let other = self.eval(self.nodes[key_node].a)
                    if other.k != V_DICT: return pv_unknown()
                    for j in 0..self.dkeys[other.n as i32].items.len() as i32:
                        let k = pv_copy(&self.dkeys[other.n as i32].items[j])
                        let v = pv_copy(&self.dvals[other.n as i32].items[j])
                        self.dkeys[dict.n as i32].items.push(k)
                        self.dvals[dict.n as i32].items.push(v)
                    i = i + 2
                    continue
                let key = self.eval(key_node)
                let value = self.eval(self.nodes[node].kids[i + 1])
                self.dkeys[dict.n as i32].items.push(key)
                self.dvals[dict.n as i32].items.push(value)
                i = i + 2
            return dict
        if kind == N_DICTCOMP:
            let iter = self.eval(self.nodes[node].kids[1])
            if iter.k != V_LIST: return pv_unknown()
            let dict = self.new_dict()
            var source: List[PyVal] = List.new()
            for i in 0..self.lists[iter.n as i32].items.len() as i32: source.push(pv_copy(&self.lists[iter.n as i32].items[i]))
            for item in source:
                self.bind_targets(self.nodes[node].kids[0], item)
                if self.nodes[node].c >= 0:
                    let t = self.truth(&self.eval(self.nodes[node].c))
                    if t < 0: return pv_unknown()
                    if t == 0: continue
                let key = self.eval(self.nodes[node].a)
                let value = self.eval(self.nodes[node].kids[2])
                self.dkeys[dict.n as i32].items.push(key)
                self.dvals[dict.n as i32].items.push(value)
            return dict
        if kind == N_ATTR:
            let target = self.eval(self.nodes[node].a)
            let name = self.nodes[node].s.clone()
            return self.attribute(&target, name, line)
        if kind == N_CALL: return self.call(node)
        if kind == N_SUB:
            let target = self.eval(self.nodes[node].a)
            let index = self.eval(self.nodes[node].b)
            return self.subscript(&target, &index)
        if kind == N_NOT:
            let t = self.truth(&self.eval(self.nodes[node].a))
            return if t < 0: pv_unknown() else: pv_bool(t == 0)
        if kind == N_NEG:
            let v = self.eval(self.nodes[node].a)
            return if v.k == V_INT: pv(V_INT, 0 - v.n, "") else: pv_unknown()
        if kind == N_AND or kind == N_OR:
            // `a and b` is a when a is false, else b; `or` mirrors it. A side
            // that decides the result alone decides it though the other is
            // not known.
            let left = self.eval(self.nodes[node].a)
            let lt = self.truth(&left)
            let decides = if kind == N_AND: 0 else: 1
            if lt == decides: return left
            let right = self.eval(self.nodes[node].b)
            if lt >= 0: return right
            return if self.truth(&right) == decides: right else: pv_unknown()
        if kind == N_CMP:
            let left = self.eval(self.nodes[node].a)
            let right = self.eval(self.nodes[node].b)
            let op = self.nodes[node].s.clone()
            if op == "==" or op == "!=":
                let e = self.equal(&left, &right)
                return if e < 0: pv_unknown() else: pv_bool((e == 1) == (op == "=="))
            if op == "in" or op == "not in":
                let c = self.contains(&left, &right)
                return if c < 0: pv_unknown() else: pv_bool((c == 1) == (op == "in"))
            if left.k == V_UNKNOWN or right.k == V_UNKNOWN or left.k == V_SINK or right.k == V_SINK: return pv_unknown()
            let o = self.order(&left, &right)
            if o == 2: return pv_unknown()
            if op == "<": return pv_bool(o < 0)
            if op == "<=": return pv_bool(o <= 0)
            if op == ">": return pv_bool(o > 0)
            return pv_bool(o >= 0)
        if kind == N_COND:
            let t = self.truth(&self.eval(self.nodes[node].a))
            if t < 0: return pv_unknown()
            return if t == 1: self.eval(self.nodes[node].b) else: self.eval(self.nodes[node].c)
        if kind == N_BIN:
            let left = self.plain(&self.eval(self.nodes[node].a))
            let right = self.plain(&self.eval(self.nodes[node].b))
            let op = self.nodes[node].s.clone()
            if op == "+":
                if left.k == V_LIST and right.k == V_LIST:
                    var items: List[PyVal] = List.new()
                    for i in 0..self.lists[left.n as i32].items.len() as i32: items.push(pv_copy(&self.lists[left.n as i32].items[i]))
                    for i in 0..self.lists[right.n as i32].items.len() as i32: items.push(pv_copy(&self.lists[right.n as i32].items[i]))
                    return self.new_list(move items)
                if left.k == V_INT and right.k == V_INT: return pv(V_INT, left.n + right.n, "")
                if (left.k == V_STR or left.k == V_OPT) and (right.k == V_STR or right.k == V_OPT): return pv_str(left.s ++ right.s)
            if op == "-" and left.k == V_INT and right.k == V_INT: return pv(V_INT, left.n - right.n, "")
            if op == "*" and left.k == V_INT and right.k == V_INT: return pv(V_INT, left.n * right.n, "")
            return pv_unknown()
        if kind == N_COMP:
            let iter = self.eval(self.nodes[node].b)
            if iter.k != V_LIST: return pv_unknown()
            var items: List[PyVal] = List.new()
            var source: List[PyVal] = List.new()
            for i in 0..self.lists[iter.n as i32].items.len() as i32: source.push(pv_copy(&self.lists[iter.n as i32].items[i]))
            for item in source:
                self.bind_targets(self.nodes[node].kids[0], item)
                if self.nodes[node].c >= 0:
                    let t = self.truth(&self.eval(self.nodes[node].c))
                    if t < 0: return pv_unknown()
                    if t == 0: continue
                items.push(self.eval(self.nodes[node].a))
            return self.new_list(move items)
        pv_unknown()

    // ── Statements ──

    // Binds a `for`'s names to one item: the item, or its parts.
    mut fn bind_targets(targets: i32, item: &PyVal):
        let count = self.nodes[targets].kids.len() as i32
        if count == 1:
            let name = self.nodes[self.nodes[targets].kids[0]].s.clone()
            self.bind(name, pv_copy(item))
            return
        for i in 0..count:
            let name = self.nodes[self.nodes[targets].kids[i]].s.clone()
            if item.k == V_LIST and i < self.lists[item.n as i32].items.len() as i32: self.bind(name, pv_copy(&self.lists[item.n as i32].items[i]))
            else: self.bind(name, pv_unknown())

    mut fn assign(target: i32, value: PyVal, line: i32):
        let kind = self.nodes[target].kind
        if kind == N_NAME:
            let name = self.nodes[target].s.clone()
            self.bind(name, value)
            return
        if kind == N_LIST:
            for i in 0..self.nodes[target].kids.len() as i32:
                if value.k == V_LIST and i < self.lists[value.n as i32].items.len() as i32: self.assign(self.nodes[target].kids[i], pv_copy(&self.lists[value.n as i32].items[i]), line)
                else: self.assign(self.nodes[target].kids[i], pv_unknown(), line)
            return
        if kind == N_ATTR:
            let owner = self.eval(self.nodes[target].a)
            if owner.k != V_OBJ: return
            let obj = owner.n as i32
            let name = self.nodes[target].s.clone()
            if self.objs[obj].cls == "options":
                self.obj_set(obj, name, pv(V_OPT, 0, py_option_text(&self.plain(&value))))
                return
            if self.objs[obj].cls == "cppinfo" and value.k != V_LIST and (name == "libs" or name == "system_libs" or name == "frameworks" or name == "requires" or name == "libdirs" or name == "exelinkflags" or name == "defines"):
                self.note(line, "cpp_info." ++ name ++ " is assigned something that could not be evaluated")
                return
            self.obj_set(obj, name, value)
            return
        if kind == N_SUB:
            let owner = self.eval(self.nodes[target].a)
            let index = self.eval(self.nodes[target].b)
            if owner.k == V_DICT:
                let id = owner.n as i32
                for i in 0..self.dkeys[id].items.len() as i32:
                    if self.equal(&index, &self.dkeys[id].items[i]) == 1:
                        self.dvals[id].items[i] = value
                        return
                self.dkeys[id].items.push(index)
                self.dvals[id].items.push(value)

    // Runs a node's statements (its kids); how it ended.
    mut fn exec_block(node: i32) -> i32:
        for i in 0..self.nodes[node].kids.len() as i32:
            let flow = self.exec(self.nodes[node].kids[i])
            if flow != PY_NORMAL: return flow
        PY_NORMAL

    mut fn exec(node: i32) -> i32:
        self.steps = self.steps + 1
        if self.steps > PY_STEP_LIMIT:
            if self.problem.len() == 0: self.problem = "the recipe did not finish evaluating"
            return PY_RETURN
        let kind = self.nodes[node].kind
        let line = self.nodes[node].line
        if kind == N_EXPR:
            if self.nodes[self.nodes[node].a].kind == N_UNSUPPORTED: self.note(line, "a '" ++ self.nodes[self.nodes[node].a].s ++ "' statement is not evaluated")
            else:
                let _ = self.eval(self.nodes[node].a)
            return PY_NORMAL
        if kind == N_ASSIGN:
            let value = self.eval(self.nodes[node].b)
            self.assign(self.nodes[node].a, value, line)
            return PY_NORMAL
        if kind == N_AUG:
            let current = self.eval(self.nodes[node].a)
            let value = self.eval(self.nodes[node].b)
            if current.k == V_LIST and self.nodes[node].s == "+":
                // `list += other` grows the list in place.
                let _ = self.call_method(&current, "extend", &py_one(value), line)
                return PY_NORMAL
            var result = pv_unknown()
            if self.nodes[node].s == "+":
                if (current.k == V_STR or current.k == V_OPT) and (value.k == V_STR or value.k == V_OPT): result = pv_str(current.s ++ value.s)
                else if current.k == V_INT and value.k == V_INT: result = pv(V_INT, current.n + value.n, "")
            self.assign(self.nodes[node].a, result, line)
            return PY_NORMAL
        if kind == N_IF:
            let t = self.truth(&self.eval(self.nodes[node].a))
            if t < 0:
                self.note(line, "an 'if' could not be decided; neither branch was taken")
                return PY_NORMAL
            if t == 1: return self.exec_block(node)
            if self.nodes[node].b >= 0: return self.exec_block(self.nodes[node].b)
            return PY_NORMAL
        if kind == N_BLOCK: return self.exec_block(node)
        if kind == N_FOR:
            let iter = self.eval(self.nodes[node].b)
            if iter.k != V_LIST:
                if iter.k != V_SINK: self.note(line, "a 'for' runs over something that could not be evaluated; its body was not run")
                return PY_NORMAL
            var source: List[PyVal] = List.new()
            for i in 0..self.lists[iter.n as i32].items.len() as i32: source.push(pv_copy(&self.lists[iter.n as i32].items[i]))
            for item in source:
                self.bind_targets(self.nodes[node].a, item)
                let flow = self.exec_block(node)
                if flow == PY_BREAK: break
                if flow == PY_RETURN: return flow
            return PY_NORMAL
        if kind == N_RETURN:
            self.ret = if self.nodes[node].a >= 0: self.eval(self.nodes[node].a) else: pv_none()
            return PY_RETURN
        if kind == N_BREAK: return PY_BREAK
        if kind == N_CONTINUE: return PY_CONTINUE
        if kind == N_RAISE: return PY_RETURN
        if kind == N_DEL:
            let target = self.nodes[node].a
            if self.nodes[target].kind == N_ATTR:
                let owner = self.eval(self.nodes[target].a)
                let name = self.nodes[target].s.clone()
                if owner.k == V_OBJ: self.obj_remove(owner.n as i32, name)
            return PY_NORMAL
        PY_NORMAL

fn py_one(value: PyVal) -> List[PyVal]:
    var out: List[PyVal] = List.new()
    out.push(value)
    out

// ── The recipe ───────────────────────────────────────────────────────

fn recipe_empty_component(name: &str): RecipeComponent { name: name.to_owned(), libs: List.new(), system_libs: List.new(), frameworks: List.new(), libdirs: List.new(), includedirs: List.new(), defines: List.new(), exelinkflags: List.new(), requires: List.new() }

fn recipe_failed(problem: &str): RecipePackageInfo { ok: false, problem: problem.to_owned(), notes: List.new(), root: recipe_empty_component(""), components: List.new() }

impl PyInterp:
    mut fn setting(value: &str) -> PyVal:
        let obj = self.new_obj("setting")
        self.obj_set(obj, "value", pv_str(value))
        pv(V_OBJ, obj as i64, "")

    // A cpp_info list attribute as text; an entry that is not text is noted.
    mut fn component_strings(obj: i32, name: &str, component: &str) -> List[str]:
        var out: List[str] = List.new()
        let list = self.cppinfo_attr(obj, name)
        if list.k != V_LIST: return out
        for i in 0..self.lists[list.n as i32].items.len() as i32:
            let text = self.to_text(&self.lists[list.n as i32].items[i])
            if text.k == V_STR: out.push(text.s.clone())
            else: self.note(0, "an entry of " ++ (if component.len() > 0: "component '" ++ component ++ "' " else: "") ++ "cpp_info." ++ name ++ " could not be evaluated")
        out

    mut fn component(obj: i32, name: &str) -> RecipeComponent:
        RecipeComponent { name: name.to_owned(), libs: self.component_strings(obj, "libs", name), system_libs: self.component_strings(obj, "system_libs", name), frameworks: self.component_strings(obj, "frameworks", name), libdirs: self.component_strings(obj, "libdirs", name), includedirs: self.component_strings(obj, "includedirs", name), defines: self.component_strings(obj, "defines", name), exelinkflags: self.component_strings(obj, "exelinkflags", name), requires: self.component_strings(obj, "requires", name) }

    // Runs the recipe method `name` when the recipe defines it.
    mut fn run_method(name: &str) -> bool:
        for i in 0..self.method_names.len() as i32:
            if self.method_names[i] != name: continue
            let _ = self.call_def(self.method_nodes[i], List.new(), self.nodes[self.method_nodes[i]].line)
            return true
        false

// The recipe's ConanFile class: the one that defines `package_info`, else
// the last class in the file.
fn recipe_class(tree: &PyModule) -> i32:
    var last = -1
    for t in tree.top:
        if tree.nodes[t].kind != N_CLASS: continue
        last = t
        for k in tree.nodes[t].kids:
            if tree.nodes[k].kind == N_DEF and tree.nodes[k].s.split("\n")[0] == "package_info": return t
    last

fn recipe_interp(recipe: &str, env: &RecipeEnv) -> (PyInterp, str):
    var tree = py_parse(recipe)
    var ip = PyInterp { nodes: List.new(), lists: List.new(), dkeys: List.new(), dvals: List.new(), objs: List.new(), recv: List.new(), frame_names: List.new(), frame_vals: List.new(), method_names: List.new(), method_nodes: List.new(), attr_names: List.new(), attr_vals: List.new(), func_names: List.new(), func_nodes: List.new(), self_obj: 0, env: RecipeEnv { os: env.os.clone(), arch: env.arch.clone(), compiler: env.compiler.clone(), compiler_version: env.compiler_version.clone(), build_type: env.build_type.clone(), version: env.version.clone(), package_folder: env.package_folder.clone(), source_folder: env.source_folder.clone(), options: List.new(), options_known: env.options_known }, notes: List.new(), ret: pv_none(), steps: 0, depth: 0, problem: "", reqs: List.new(), tool_reqs: List.new(), toolchains: List.new() }
    if tree.problem.len() > 0: return (ip, "the recipe could not be read: " ++ tree.problem)
    let cls_node = recipe_class(&tree)
    if cls_node < 0: return (ip, "the recipe defines no class")
    ip.frame_names.push(PyNames { items: List.new() })
    ip.frame_vals.push(PyList { items: List.new() })
    for t in tree.top:
        if tree.nodes[t].kind == N_DEF:
            ip.func_names.push(tree.nodes[t].s.split("\n")[0].to_owned())
            ip.func_nodes.push(t)
    var class_body: List[i32] = List.new()
    for k in tree.nodes[cls_node].kids:
        if tree.nodes[k].kind == N_DEF:
            ip.method_names.push(tree.nodes[k].s.split("\n")[0].to_owned())
            ip.method_nodes.push(k)
        else: class_body.push(k)
    var top_assigns: List[i32] = List.new()
    for t in tree.top:
        if tree.nodes[t].kind == N_ASSIGN: top_assigns.push(t)
    ip.nodes = move tree.nodes
    for t in top_assigns:
        let _ = ip.exec(t)
    // The class body is statements too (`default_options = {…}` then
    // `default_options["fPIC"] = True`): run in order, and what they bind
    // is what `self.<name>` finds.
    ip.frame_names.push(PyNames { items: List.new() })
    ip.frame_vals.push(PyList { items: List.new() })
    for k in class_body:
        let _ = ip.exec(k)
    let class_frame: i32 = ip.frame_names.len() as i32 - 1
    for i in 0..ip.frame_names[class_frame].items.len() as i32:
        let name = ip.frame_names[class_frame].items[i].clone()
        let value = pv_copy(&ip.frame_vals[class_frame].items[i])
        ip.attr_names.push(name)
        ip.attr_vals.push(value)
    let _class_names = ip.frame_names.pop()
    let _class_vals = ip.frame_vals.pop()

    // `self`, its settings and its options.
    ip.self_obj = ip.new_obj("self")
    let settings = ip.new_obj("settings")
    let os_setting = ip.setting(env.os)
    ip.obj_set(settings, "os", os_setting)
    let arch_setting = ip.setting(env.arch)
    ip.obj_set(settings, "arch", arch_setting)
    let build_type_setting = ip.setting(env.build_type)
    ip.obj_set(settings, "build_type", build_type_setting)
    let compiler = ip.setting(env.compiler)
    let compiler_version = ip.setting(env.compiler_version)
    ip.obj_set(compiler.n as i32, "version", compiler_version)
    ip.obj_set(settings, "compiler", compiler)
    let self_obj: i32 = ip.self_obj
    ip.obj_set(self_obj, "settings", pv(V_OBJ, settings as i64, ""))
    ip.obj_set(self_obj, "settings_build", pv(V_OBJ, settings as i64, ""))
    ip.obj_set(self_obj, "settings_target", pv_none())
    ip.obj_set(self_obj, "version", pv_str(env.version))
    ip.obj_set(self_obj, "package_folder", pv_str(env.package_folder))
    ip.obj_set(self_obj, "source_folder", pv_str(env.source_folder))
    ip.obj_set(self_obj, "export_sources_folder", pv_str(env.source_folder))
    let options = ip.new_obj("options")
    ip.obj_set(self_obj, "options", pv(V_OBJ, options as i64, ""))
    let cpp_info = ip.new_obj("cppinfo")
    ip.obj_set(self_obj, "cpp_info", pv(V_OBJ, cpp_info as i64, ""))
    if env.options_known:
        for line in env.options:
            let eq = line.find("=")
            if eq > 0: ip.obj_set(options, line.slice(0, eq), pv(V_OPT, 0, line.slice(eq + 1, line.len())))
    else:
        // The declared defaults, then the recipe's own adjustments to them.
        let defaults = ip.self_attr("default_options", 0)
        if defaults.k == V_DICT:
            for i in 0..ip.dkeys[defaults.n as i32].items.len() as i32:
                let key = pv_copy(&ip.dkeys[defaults.n as i32].items[i])
                if key.k != V_STR or key.s.contains(":") or key.s.contains("/"): continue
                ip.obj_set(options, key.s, pv(V_OPT, 0, py_option_text(&ip.dvals[defaults.n as i32].items[i])))
        // A package built here is a static library.
        if ip.obj_find(options, "shared") >= 0: ip.obj_set(options, "shared", pv(V_OPT, 0, "False"))
        let _c = ip.run_method("config_options")
        let _d = ip.run_method("configure")
    (ip, "")

// The options a package built here is made with, as conaninfo spells them:
// the recipe's defaults after its `config_options` and `configure`.
pub fn recipe_built_options(recipe: &str, env: &RecipeEnv) -> List[str]:
    var out: List[str] = List.new()
    let (ip, problem) = recipe_interp(recipe, env)
    if problem.len() > 0: return out
    let self_obj: i32 = ip.self_obj
    let at = ip.obj_find(self_obj, "options")
    if at < 0: return out
    let options = ip.objs[self_obj].vals[at].n as i32
    for i in 0..ip.objs[options].names.len() as i32: out.push(ip.objs[options].names[i] ++ "=" ++ ip.objs[options].vals[i].s)
    out

// `package_info`, run: what the package's cpp_info and its components hold.
pub fn recipe_package_info(recipe: &str, env: &RecipeEnv) -> RecipePackageInfo:
    let (ip0, problem) = recipe_interp(recipe, env)
    if problem.len() > 0: return recipe_failed(problem)
    var ip = ip0
    ip.notes = List.new()
    if not ip.run_method("package_info"): return recipe_failed("the recipe defines no package_info")
    if ip.problem.len() > 0: return recipe_failed(ip.problem)
    let self_obj: i32 = ip.self_obj
    let cpp_info = ip.objs[self_obj].vals[ip.obj_find(self_obj, "cpp_info")].n as i32
    let root = ip.component(cpp_info, "")
    var components: List[RecipeComponent] = List.new()
    let comps_at = ip.obj_find(cpp_info, "components")
    if comps_at >= 0:
        let comps = ip.objs[cpp_info].vals[comps_at].n as i32
        var names: List[str] = List.new()
        var ids: List[i32] = List.new()
        for i in 0..ip.objs[comps].names.len() as i32:
            names.push(ip.objs[comps].names[i].clone())
            ids.push(ip.objs[comps].vals[i].n as i32)
        for i in 0..names.len() as i32: components.push(ip.component(ids[i], names[i]))
    RecipePackageInfo { ok: true, problem: "", notes: move ip.notes, root, components }

// What `requirements` and `build_requirements` ask for: the packages the
// library needs, and the tools its build runs, as the recipe writes them
// (`zlib/[>=1.2.11 <2]`).
pub type RecipeRequirements { ok: bool, problem: str, notes: List[str], requires: List[str], tool_requires: List[str] }

pub fn recipe_requirements(recipe: &str, env: &RecipeEnv) -> RecipeRequirements:
    let (ip0, problem) = recipe_interp(recipe, env)
    if problem.len() > 0: return RecipeRequirements { ok: false, problem, notes: List.new(), requires: List.new(), tool_requires: List.new() }
    var ip = ip0
    ip.notes = List.new()
    // The class may state its requirements as an attribute instead.
    let stated = ip.self_attr("requires", 0)
    if stated.k == V_STR: ip.reqs.push(stated.s.clone())
    if stated.k == V_LIST:
        for i in 0..ip.lists[stated.n as i32].items.len() as i32:
            let reference = pv_copy(&ip.lists[stated.n as i32].items[i])
            if reference.k == V_STR: ip.reqs.push(reference.s.clone())
    let _r = ip.run_method("requirements")
    let _b = ip.run_method("build_requirements")
    if ip.problem.len() > 0: return RecipeRequirements { ok: false, problem: move ip.problem, notes: List.new(), requires: List.new(), tool_requires: List.new() }
    RecipeRequirements { ok: true, problem: "", notes: move ip.notes, requires: move ip.reqs, tool_requires: move ip.tool_reqs }

// The variables `generate` sets on its CMakeToolchain, as CMake spells
// their values; `unknown` names each one whose value could not be evaluated.
pub type RecipeCMake { ok: bool, problem: str, notes: List[str], names: List[str], values: List[str], unknown: List[str] }

pub fn recipe_cmake_variables(recipe: &str, env: &RecipeEnv) -> RecipeCMake:
    var out = RecipeCMake { ok: false, problem: "", notes: List.new(), names: List.new(), values: List.new(), unknown: List.new() }
    let (ip0, problem) = recipe_interp(recipe, env)
    if problem.len() > 0:
        out.problem = problem
        return out
    var ip = ip0
    ip.notes = List.new()
    let _g = ip.run_method("generate")
    if ip.problem.len() > 0:
        out.problem = move ip.problem
        return out
    for ti in 0..ip.toolchains.len() as i32:
        let tc: i32 = ip.toolchains[ti]
        for attr in ["variables", "cache_variables"]:
            let at = ip.obj_find(tc, attr)
            if at < 0: continue
            let dict = pv_copy(&ip.objs[tc].vals[at])
            if dict.k != V_DICT: continue
            for i in 0..ip.dkeys[dict.n as i32].items.len() as i32:
                let key = pv_copy(&ip.dkeys[dict.n as i32].items[i])
                if key.k != V_STR: continue
                let value = ip.plain(&ip.dvals[dict.n as i32].items[i])
                // An unset variable (None) is not passed.
                if value.k == V_OPT and value.s == "None": continue
                if value.k == V_NONE: continue
                var text = ""
                if value.k == V_BOOL: text = if value.n != 0: "ON" else: "OFF"
                else if value.k == V_OPT and (value.s == "True" or value.s == "False"): text = if value.s == "True": "ON" else: "OFF"
                else if value.k == V_STR or value.k == V_OPT or value.k == V_VER or value.k == V_INT: text = py_option_text(&value)
                else:
                    out.unknown.push(key.s.clone())
                    continue
                var slot = -1
                for k in 0..out.names.len() as i32:
                    if out.names[k] == key.s: slot = k
                if slot >= 0: out.values[slot] = text
                else:
                    out.names.push(key.s.clone())
                    out.values.push(text)
    out.ok = true
    out.notes = move ip.notes
    out
