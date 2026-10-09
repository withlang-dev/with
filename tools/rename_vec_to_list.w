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
// `path:line: literal`), for the reviewed pass. --apply-text rewrites the
// reviewed pass inside string literals and comments only: a capitalized
// `Vec` word or compound part (`Vec`, `VecIter`, `SortedVec`) becomes
// `List`; `Vec<` (Rust), `Vector`, `Vec2` and lowercase `vec` (runtime
// symbol names, pinned by the seed) are kept.
//
//   with run tools/rename_vec_to_list.w --apply-text FILE...

use std.fs
use std.process
use Lexer
use Token

fn is_upper(c: u8) -> bool: c >= 'A' and c <= 'Z'
fn is_lower(c: u8) -> bool: (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9')

fn renamed_part(part: &str, types_only: bool) -> str:
    if part == "Vec": "List"
    else if types_only: part
    else if part == "vec": "list"
    else if part == "VEC": "LIST"
    // One-word lowercase names of the List types (`syms.veciter`).
    else if part == "veciter" or part == "vecslot" or part == "vecrange" or part == "veciterref" or part == "veciterplace" or part == "veclit" or part == "vecintoiter": "list" ++ part.slice(3, part.len())
    else: part

fn renamed(ident: &str, types_only: bool) -> str:
    if ident.starts_with("with_") or ident == "splat_vec": return ident
    var out = ""
    var start: i64 = 0
    let n = ident.len()
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
fn text_renamed(text: &str) -> str:
    var out: str = text
    for _ in 0..64:
        let next = /(?<=[a-z])Vec\b/.replace(/\bVec(?=[A-Z][a-z])/.replace(/\bVec\b(?!<)/.replace(out, "List"), "List"), "List")
        if next == out: return out
        out = next
    out

fn is_text_token(tag: i32) -> bool:
    tag == TokenKind.TK_STRING_LIT or tag == TokenKind.TK_STRING_START or tag == TokenKind.TK_STRING_END or tag == TokenKind.TK_STRING_FRAGMENT or tag == TokenKind.TK_COMMENT

var apply = false
var apply_text = false
var strings = false
var files: List[str] = []
for i in 1..argv.len():
    if argv[i] == "--apply": apply = true
    else if argv[i] == "--strings": strings = true
    else if argv[i] == "--apply-text": apply_text = true
    else: files.push(argv[i])

if apply_text:
    var changed_files = 0
    for path in files:
        let text = read_file(path) ?? ""
        var lexer = Lexer.init(text, 0)
        let tokens = lexer.tokenize_with_comments()
        var out = ""
        var at = 0
        for t in 0..tokens.len():
            if not is_text_token(tokens.get_tag(t)): continue
            let start = tokens.get_start(t)
            let end = tokens.get_end(t)
            let old = text.slice(start, end)
            let new = text_renamed(old)
            if new == old: continue
            out = out ++ text.slice(at, start) ++ new
            at = end
        if at > 0:
            out = out ++ text.slice(at, text.len())
            if write_file(path, out) != 0:
                print(f"rename-vec-to-list: cannot write {path}")
                exit_code(1)
            changed_files += 1
    print(f"rename-vec-to-list: rewrote text in {changed_files} files")
    exit_code(0)

fn line_of(text: &str, at: i32) -> i32:
    var line = 1
    for i in 0..at:
        if text[i] == '\n': line += 1
    line

if strings:
    for path in files:
        let text = read_file(path) ?? ""
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
    let text = read_file(path) ?? ""
    let types_only = path.ends_with("Vector.w")
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var out = ""
    var at = 0
    var changed = false
    for t in 0..tokens.len():
        let tag = tokens.get_tag(t)
        if tag != TokenKind.TK_IDENT and tag != TokenKind.TK_DOT_IDENT: continue
        // A dot-identifier (`.Vec`, `.VEC_NEW`) carries its dot.
        let start = if tag == TokenKind.TK_DOT_IDENT: tokens.get_start(t) + 1 else: tokens.get_start(t)
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
