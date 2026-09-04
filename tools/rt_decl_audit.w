// D30 R2c: audit every `extern fn with_*` decl against the rt definition of
// the same name. #761's corruption class is exactly this — one symbol whose
// ABI contract is derived twice — so the rt def is truth and any decl that
// disagrees is a live divergence.
//
//   with run tools/rt_decl_audit.w        # from the repo root; exits 1 on any divergence
//
// Note: `TokenList` is private to src/Token.w, so all token work has to stay
// inside one function; normalization cannot be factored out.
use std.fs
use std.process
use Lexer
use Token

fn owned(s: &str): s ++ ""

// A `fn` def's return type ends at `:`; an `extern fn` decl has no body, so
// it ends at the line break instead.
fn ends_return_type(tag: i32) -> bool:
    tag == TokenKind.TK_COLON or tag == TokenKind.TK_NEWLINE or tag == TokenKind.TK_EOF

fn line_of(text: &str, off: i32) -> i32:
    var n = 1
    var i = 0
    while i < off:
        if text[i] == 10: n = n + 1
        i = i + 1
    n

// One "name|sig|file:line" record per matching decl. `sig` is normalized to
// parameter TYPES plus return type, names dropped:
// `fn f(dst: *mut u8, n: i64) -> Unit` -> "(*mut u8,i64)->Unit"
fn scan(path: &str, want_extern: bool, aliases: &Vec[str]) -> Vec[str]:
    var found: Vec[str] = Vec.new()
    let text = read_file(path)
    if text.len() == 0: return found
    var lexer = Lexer.init(text.slice(0, text.len()), 0)
    let toks = lexer.tokenize()
    let n = toks.len() as i32
    for i in 0..n:
        if toks.get_tag(i) != TokenKind.TK_KW_FN: continue
        if i + 1 >= n or toks.get_tag(i + 1) != TokenKind.TK_IDENT: continue
        let is_extern = i > 0 and toks.get_tag(i - 1) == TokenKind.TK_KW_EXTERN
        if is_extern != want_extern: continue
        let name = text.slice(toks.get_start(i + 1) as i64, toks.get_end(i + 1) as i64)
        if not name.starts_with("with_"): continue

        var sig = "("
        var k = i + 2
        var depth = 0
        var after_colon = false
        var first_word = true
        var done = false
        while k < n and not done:
            let tag = toks.get_tag(k)
            if tag == TokenKind.TK_L_PAREN:
                depth = depth + 1
                if depth == 1:
                    k = k + 1
                    continue
            if tag == TokenKind.TK_R_PAREN:
                depth = depth - 1
                if depth == 0:
                    sig = sig ++ ")"
                    var j = k + 1
                    if j < n and toks.get_tag(j) == TokenKind.TK_ARROW:
                        j = j + 1
                        sig = sig ++ "->"
                        while j < n and not ends_return_type(toks.get_tag(j)):
                            sig = sig ++ text.slice(toks.get_start(j) as i64, toks.get_end(j) as i64)
                            j = j + 1
                    else:
                        sig = sig ++ "->Unit"
                    done = true
                    continue
            if depth == 1 and tag == TokenKind.TK_COMMA:
                after_colon = false
                first_word = true
                sig = sig ++ ","
                k = k + 1
                continue
            if depth == 1 and tag == TokenKind.TK_COLON:
                after_colon = true
                k = k + 1
                continue
            // Inside a parameter's type, every token counts — including the
            // parens of a fn-pointer type like `*const fn(*mut u8) -> Unit`.
            if after_colon:
                if not first_word: sig = sig ++ " "
                sig = sig ++ text.slice(toks.get_start(k) as i64, toks.get_end(k) as i64)
                first_word = false
            k = k + 1
        found.push(f"{name}|{expand_aliases(sig, aliases)}|{path}:{line_of(text, toks.get_start(i))}")
    found

// rt's own `type X = ...` aliases, as "name|expansion" records. A def spelled
// through an alias and a decl spelled through its expansion are the same
// contract; the audit must not report them as divergent.
fn load_aliases(root: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    for p in list_files_text(root).split("\n"):
        if not p.ends_with(".w"): continue
        for line in read_file(p).split("\n"):
            if not line.starts_with("type "): continue
            let eq = line.find(" = ")
            if eq < 0: continue
            let alias = line.slice(5, eq as i64)
            let body = line.slice((eq + 3) as i64, line.len())
            out.push(f"{alias}|{normalize_type_text(body)}")
    out

// Whitespace is never significant inside a With type, so the comparison key
// is the type text with every space removed: `* const fn ( * mut u8 )` and
// `*const fn(*mut u8)` are the same contract.
fn normalize_type_text(body: &str) -> str:
    body.replace(" ", "")

fn expand_aliases(sig: &str, rt_aliases: &Vec[str]) -> str:
    var out = normalize_type_text(sig)
    for i in 0..rt_aliases.len() as i32:
        let rec = rt_aliases[i]
        let bar = rec.find("|")
        let alias = rec.slice(0, bar as i64)
        let body = rec.slice((bar + 1) as i64, rec.len())
        out = out.replace(alias, body)
    out

fn collect(root: &str, want_extern: bool, aliases: &Vec[str]) -> Vec[str]:
    var all: Vec[str] = Vec.new()
    for p in list_files_text(root).split("\n"):
        if not p.ends_with(".w"): continue
        for r in scan(p, want_extern, aliases):
            all.push(owned(r))
    all

fn field(rec: &str, k: i32) -> str:
    var i = 0
    for part in rec.split("|"):
        if i == k: return owned(part)
        i = i + 1
    ""

let aliases = load_aliases("rt")
let defs = collect("rt", false, &aliases)
var decls: Vec[str] = Vec.new()
var roots: Vec[str] = Vec.new()
roots.push("rt")
roots.push("lib/std")
roots.push("src")
roots.push("tools")
roots.push("test")
for ri in 0..roots.len() as i32:
    for r in collect(roots[ri], true, &aliases):
        decls.push(owned(r))

var bad = 0
for di in 0..defs.len() as i32:
    let dname = field(defs[di], 0)
    let dsig = field(defs[di], 1)
    let dat = field(defs[di], 2)
    for ei in 0..decls.len() as i32:
        let ename = field(decls[ei], 0)
        if ename != dname: continue
        let esig = field(decls[ei], 1)
        if esig == dsig: continue
        print(f"{dname}\n  def  {dsig}   [{dat}]\n  decl {esig}   [{field(decls[ei], 2)}]")
        bad = bad + 1
print(f"-- {bad} divergent decls / {defs.len()} rt defs / {decls.len()} extern with_* decls")
exit_code(if bad > 0: 1 else: 0)
