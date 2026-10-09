// rename_vec_to_list -- D118 step (c): the growable sequence is `List`, in
// identifier tokens. The Lexer decides what an identifier is, so string
// literals and comments are untouched (they get the reviewed pass). An
// identifier is split into word parts at `_` and at a lower-to-upper case
// step; a part that is exactly `vec`, `Vec` or `VEC` becomes `list`, `List`
// or `LIST`. `vector`, `ovector`, `Vec2` and every other part are kept.
// Identifiers starting `with_` are the runtime's exported seam: the seed
// calls them by name, so they rename one seed later. In the SIMD files
// (`*Vector.w`) a lowercase `vec` is the SIMD vector, so only the type part
// `Vec` is renamed there; `splat_vec` (a SIMD broadcast) is kept everywhere.
//
//   with run tools/rename_vec_to_list.w [--apply] FILE...
//   with run tools/rename_vec_to_list.w --strings FILE...
//
// Dry-run prints `old -> new  count` per renamed identifier; --apply writes
// the files. --strings lists every string literal that says `Vec` (as
// `path:line: literal`), for the reviewed pass.

use std.fs
use std.process
use Lexer
use Token

fn is_upper(c: u8) -> bool: c >= 'A' and c <= 'Z'
fn is_lower(c: u8) -> bool: (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9')

fn renamed_part(part: &str, types_only: bool) -> str:
    if part == "Vec": "List"
    else if types_only: part.clone()
    else if part == "vec": "list"
    else if part == "VEC": "LIST"
    else: part.clone()

fn renamed(ident: &str, types_only: bool) -> str:
    if ident.starts_with("with_") or ident == "splat_vec": return ident.clone()
    var out = ""
    var start = 0
    let n = ident.len() as i32
    for i in 0..n + 1:
        if i == n or ident[i] == '_':
            out = out ++ renamed_part(ident.slice(start, i), types_only)
            if i < n: out = out ++ "_"
            start = i + 1
        else if i > start and is_upper(ident[i]) and is_lower(ident[i - 1]):
            out = out ++ renamed_part(ident.slice(start, i), types_only)
            start = i
    out

let argv = args()
var apply = false
var strings = false
var files: Vec[str] = []
for i in 1..argv.len():
    if argv[i] == "--apply": apply = true
    else if argv[i] == "--strings": strings = true
    else: files.push(argv[i].clone())

fn line_of(text: &str, at: i32) -> i32:
    var line = 1
    for i in 0..at:
        if text[i] == '\n': line += 1
    line

if strings:
    for path in files:
        let text = read_file(path).unwrap_or("".clone())
        var lexer = Lexer.init(text, 0)
        let tokens = lexer.tokenize()
        for t in 0..tokens.len():
            let tag = tokens.get_tag(t)
            if tag == TokenKind.TK_IDENT or tag == TokenKind.TK_INT_LIT or tag == TokenKind.TK_FLOAT_LIT: continue
            let lit = text.slice(tokens.get_start(t), tokens.get_end(t))
            if lit.starts_with("\"") or lit.starts_with("f\"") or lit.starts_with("r\""):
                if lit.contains("Vec"): print(f"{path}:{line_of(text, tokens.get_start(t))}: {lit}")
    exit_code(0)

var counts: HashMap[str, i32] = HashMap.new()
for path in files:
    let text = read_file(path).unwrap_or("".clone())
    let types_only = path.ends_with("Vector.w")
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var out = ""
    var at = 0
    var changed = false
    for t in 0..tokens.len():
        if tokens.get_tag(t) != TokenKind.TK_IDENT: continue
        let start = tokens.get_start(t)
        let end = tokens.get_end(t)
        let old = text.slice(start, end)
        let new = renamed(old, types_only)
        if new == old: continue
        out = out ++ text.slice(at, start) ++ new
        at = end
        changed = true
        let key = f"{old} -> {new}"
        counts.insert(key, (counts.get(&key) ?? &0) + 1)
    if changed and apply:
        out = out ++ text.slice(at, text.len())
        if write_file(path, out) != 0:
            print(f"rename-vec-to-list: cannot write {path}")
            exit_code(1)

for (key, n) in counts:
    print(f"{key}  {n}")
