// D30 R2c: rename every bare (non rt_/with_/wl_-prefixed) `extern fn` in an
// rt source to `rt_libc_<name>` with `@[link_name("<name>")]`, retargeting
// every identifier token of that name in the file. Bare libc names in the
// flat fn table collide with c_import decls and user fns once the runtime
// compiles in-unit (#761); the link_name keeps the exact C symbol. Token
// replacement is Lexer-accurate (comments/strings never rewritten).
//
//   with run tools/rename_rt_libc_externs.w rt/darwin_aarch64.w ...
use std.process
use std.fs
use Lexer
use Token

fn slice(text: &str, a: i32, b: i32): text.slice(a as i64, b as i64)

fn is_bare(name: &str) -> bool:
    not (name.starts_with("rt_") or name.starts_with("with_") or name.starts_with("wl_"))

fn renamed(name: &str) -> str:
    // Strip leading underscores for the With-side spelling (_exit →
    // rt_libc_exit, __error → rt_libc_error); the link_name keeps the truth.
    var i = 0
    while i < name.len() as i32 and name[i] == 95:
        i = i + 1
    "rt_libc_" ++ name.slice(i as i64, name.len())

fn process(path: &str) -> i32:
    let text = read_file(path) ?? ""
    if text.len() == 0:
        eprint("error: could not read " ++ path)
        return 1
    var lexer = Lexer.init(text.slice(0, text.len()), 0)
    let tokens = lexer.tokenize()
    let n = tokens.len() as i32

    // Pass 1: collect the bare extern names declared in this file.
    var names: Vec[str] = Vec.new()
    for i in 0..n:
        if tokens.get_tag(i) != TokenKind.TK_KW_EXTERN:
            continue
        if i + 2 >= n or tokens.get_tag(i + 1) != TokenKind.TK_KW_FN or tokens.get_tag(i + 2) != TokenKind.TK_IDENT:
            continue
        let name = slice(text, tokens.get_start(i + 2), tokens.get_end(i + 2))
        if is_bare(name):
            var seen = false
            for j in 0..names.len() as i32:
                if names[j] == name: seen = true
            if not seen:
                names.push(name)
    if names.len() == 0:
        print("no bare externs: " ++ path)
        return 0

    // Pass 2: rebuild the text. Every IDENT token matching a collected name
    // becomes rt_libc_<name>; each `extern fn <name>` gets the link_name
    // attribute line prepended (indentation preserved for nested decls).
    var out = ""
    var pos = 0
    var count = 0
    for i in 0..n:
        if tokens.get_tag(i) != TokenKind.TK_IDENT:
            continue
        let ts = tokens.get_start(i)
        let te = tokens.get_end(i)
        let tok = slice(text, ts, te)
        var hit = false
        for j in 0..names.len() as i32:
            if names[j] == tok: hit = true
        if not hit:
            continue
        let is_decl = i >= 2 and tokens.get_tag(i - 1) == TokenKind.TK_KW_FN and tokens.get_tag(i - 2) == TokenKind.TK_KW_EXTERN
        if is_decl:
            // Insert the attribute before the `extern` keyword, after the
            // line's leading whitespace.
            var line_start = tokens.get_start(i - 2)
            while line_start > 0 and text[line_start as i64 - 1] != 10:
                line_start = line_start - 1
            out = out ++ slice(text, pos, line_start)
            let indent = slice(text, line_start, tokens.get_start(i - 2))
            out = out ++ indent ++ "@[link_name(\"" ++ tok ++ "\")]\n"
            out = out ++ slice(text, line_start, ts)
        else:
            out = out ++ slice(text, pos, ts)
        out = out ++ renamed(tok)
        pos = te
        count = count + 1
    out = out ++ text.slice(pos as i64, text.len())
    let _ = write_file(path, out)
    print(f"{path}: renamed {count} tokens across {names.len()} externs")
    0

let argv = args()
var rc = 0
for ai in 1..argv.len() as i32:
    if process(argv[ai]) != 0:
        rc = 1
exit_code(rc)
