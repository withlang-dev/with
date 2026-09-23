// D58 migration: the `else` of `let ... else` takes a §29.13 body or a
// single diverging expression on the same line. `else` + newline + an
// indented block with no `:` is a parse error; this tool writes the colon.
//
//   let Some(v) = o else          =>   let Some(v) = o else:
//       return 0                           return 0
//
// Selection is Lexer-accurate (comments and strings are never touched): an
// `else` token directly followed by a newline token, whose logical line
// (walked back at bracket depth 0 to the previous newline) begins with
// `let` or `var`. Any other bare `else` at end of line is listed as
// "not let-else" and left for a human: it is not this rule's shape.
// Dry-run is the default.
//
//   with run tools/migrate_let_else_colon.w [--apply] <file.w | dir> ...
use std.process
use std.fs
use Lexer
use Token

fn slice(text: &str, a: i32, b: i32): text.slice(a as i64, b as i64)

fn line_of(text: &str, offset: i32) -> i32:
    var line = 1
    for i in 0..offset:
        if text[i] == '\n': line = line + 1
    line

fn process(path: &str, apply: bool) -> i32:
    let text = read_file(path) ?? ""
    if text.len() == 0: return 0
    var lexer = Lexer.init(text.slice(0, text.len()), 0)
    let tokens = lexer.tokenize()
    let n = tokens.len() as i32
    var out = ""
    var pos = 0
    var count = 0
    for i in 0..n - 1:
        if tokens.get_tag(i) != TokenKind.TK_KW_ELSE or tokens.get_tag(i + 1) != TokenKind.TK_NEWLINE: continue
        // The logical line's first token: walk back over balanced brackets
        // to the previous depth-0 newline.
        var depth = 0
        var k = i - 1
        while k >= 0:
            let t = tokens.get_tag(k)
            if t == TokenKind.TK_R_PAREN or t == TokenKind.TK_R_BRACKET or t == TokenKind.TK_R_BRACE: depth = depth + 1
            else if t == TokenKind.TK_L_PAREN or t == TokenKind.TK_L_BRACKET or t == TokenKind.TK_L_BRACE: depth = depth - 1
            else if t == TokenKind.TK_NEWLINE and depth <= 0: break
            k = k - 1
        let head = tokens.get_tag(k + 1)
        let at = tokens.get_end(i)
        if head != TokenKind.TK_KW_LET and head != TokenKind.TK_KW_VAR:
            print(f"{path}:{line_of(text, at)}: bare else at end of line, not let-else (left alone)")
            continue
        print(f"{path}:{line_of(text, at)}: let-else without ':'")
        out = out ++ slice(text, pos, at) ++ ":"
        pos = at
        count = count + 1
    if apply and count > 0:
        out = out ++ text.slice(pos as i64, text.len())
        if write_file(path, out) != 0:
            eprint(f"error: could not write {path}")
            return -1
    count

let argv = args()
var apply = false
var total = 0
var failed = false
for ai in 1..argv.len() as i32:
    let arg = argv[ai]
    if arg == "--apply":
        apply = true
        continue
    let listing = if arg.ends_with(".w"): arg.clone() else: list_files_text(arg)
    for path in listing.split("\n"):
        if not path.ends_with(".w"): continue
        let c = process(path, apply)
        if c < 0: failed = true
        else: total = total + c
let verb = if apply: "rewrote" else: "found"
print(f"{verb} {total} let-else sites without ':'")
if failed: exit_code(1)
