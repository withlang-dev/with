// Migrate compiler-proven D22 Copy-view bindings to explicit owned snapshots.
//
// The candidate compiler supplies the semantic proof and exact target type via
// its §22.3 diagnostic. This tool only uses Lexer tokens to locate that proven
// binding on the labeled source line; it never guesses from `.get()` spelling.
//
//   with run tools/migrate_d22_copy_views.w <candidate-with> [source.w] [--apply]

use std.process
use Lexer
use Token

extern fn with_exec_argv_capture(argv: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32
extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32

fn find_from(text: str, needle: str, start: i64) -> i64:
    if needle.len() == 0: return start
    var i = start
    while i + needle.len() <= text.len():
        var j: i64 = 0
        while j < needle.len() and text[i + j] == needle[j]: j = j + 1
        if j == needle.len(): return i
        i = i + 1
    -1

fn line_end(text: str, start: i64) -> i64:
    var end = start
    while end < text.len() and text[end] != 10: end = end + 1
    end

fn line_text(text: str, start: i64): text.slice(start, line_end(text, start))

fn diagnostic_source_path(path: str) -> str:
    let embedded_std = "<embedded-std>/"
    if path.starts_with(embedded_std):
        return "lib/" ++ path.slice(embedded_std.len(), path.len())
    path

fn parse_i32_text(text: str) -> i32:
    var out = 0
    for i in 0..text.len() as i32:
        let b = text[i] as i32
        if b < 48 or b > 57: return -1
        out = out * 10 + b - 48
    out

fn source_line_start(text: str, wanted: i32) -> i32:
    if wanted <= 1: return 0
    var line = 1
    var i = 0
    while i < text.len() as i32:
        if text[i] as i32 == 10:
            line = line + 1
            if line == wanted: return i + 1
        i = i + 1
    -1

fn source_line_end(text: str, start: i32) -> i32:
    var i = start
    while i < text.len() as i32 and text[i] as i32 != 10: i = i + 1
    i

type Edits {
    paths: Vec[str],
    lines: Vec[i32],
    names: Vec[str],
    types: Vec[str],
}

fn edit_key(path: str, line: i32, name: str): path ++ ":" ++ line.to_string() ++ ":" ++ name

fn has_edit(edits: &Edits, path: str, line: i32, name: str) -> bool:
    let wanted = edit_key(path, line, name)
    for i in 0..edits.paths.len() as i32:
        if edit_key(edits.paths.get(i as i64), edits.lines.get(i as i64), edits.names.get(i as i64)) == wanted: return true
    false

fn parse_diagnostics(text: str) -> Edits:
    let edits = Edits { paths: Vec.new(), lines: Vec.new(), names: Vec.new(), types: Vec.new() }
    let error_prefix = "error: cannot mutate `"
    var pos: i64 = 0
    while true:
        let start = find_from(text, error_prefix, pos)
        if start < 0: break
        let next = find_from(text, "\nerror:", start + 1)
        let block_end = if next >= 0: next else: text.len()
        let block = text.slice(start, block_end)

        let while_at = find_from(block, " while `", 0)
        let live_at = if while_at >= 0: find_from(block, "` is a live view", while_at + 8) else: -1
        if while_at < 0 or live_at < 0:
            pos = block_end
            continue
        let name = block.slice(while_at + 8, live_at)

        let path_at = find_from(block, "\n --> ", 0)
        if path_at < 0:
            pos = block_end
            continue
        let location = line_text(block, path_at + 6)
        let first_colon = find_from(location, ":", 0)
        if first_colon < 0:
            pos = block_end
            continue
        let path = diagnostic_source_path(location.slice(0, first_colon))

        let label_prefix = "= label @"
        var label_at = find_from(block, label_prefix, 0)
        var binding_line = -1
        while label_at >= 0:
            let label = line_text(block, label_at)
            if label.contains("`" ++ name ++ "` views"):
                let digits_start = label_at + label_prefix.len()
                let colon = find_from(block, ":", digits_start)
                if colon >= 0: binding_line = parse_i32_text(block.slice(digits_start, colon))
                break
            label_at = find_from(block, label_prefix, label_at + label_prefix.len())
        if binding_line < 1:
            pos = block_end
            continue

        let type_prefix = "`let " ++ name ++ ": "
        let type_at = find_from(block, type_prefix, 0)
        let type_end = if type_at >= 0: find_from(block, " = ...`", type_at + type_prefix.len()) else: -1
        if type_at < 0 or type_end < 0:
            pos = block_end
            continue
        let ty = block.slice(type_at + type_prefix.len(), type_end)
        if not has_edit(&edits, path, binding_line, name):
            edits.paths.push(path)
            edits.lines.push(binding_line)
            edits.names.push(name)
            edits.types.push(ty)
        pos = block_end
    edits

fn locate_binding_insert(text: str, line: i32, name: str) -> i32:
    let start = source_line_start(text, line)
    if start < 0: return -1
    let end = source_line_end(text, start)
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    for i in 0..tokens.len() - 2:
        let token_start = tokens.get_start(i)
        if token_start < start or token_start >= end: continue
        let tag = tokens.get_tag(i)
        if tag != TokenKind.TK_KW_LET and tag != TokenKind.TK_KW_VAR: continue
        if tokens.get_tag(i + 1) != TokenKind.TK_IDENT: continue
        let found = text.slice(tokens.get_start(i + 1) as i64, tokens.get_end(i + 1) as i64)
        if found != name: continue
        if tokens.get_tag(i + 2) != TokenKind.TK_EQ: return -1
        return tokens.get_end(i + 1)
    -1

fn apply_one(path: str, line: i32, name: str, ty: str, apply: bool) -> i32:
    let text = unsafe { with_fs_read_file(path) }
    let insert = locate_binding_insert(text, line, name)
    if insert < 0:
        print(f"error: ambiguous D22 binding site {path}:{line} `{name}`")
        return -1
    print(f"{if apply: "migrate" else: "would migrate"}: {path}:{line} let {name}: {ty}")
    if apply:
        let updated = text.slice(0, insert as i64) ++ ": " ++ ty ++ text.slice(insert as i64, text.len())
        let rc = unsafe { with_fs_write_file(path, updated) }
        if rc != 0:
            print(f"error: failed to write {path}")
            return -1
    1

fn main:
    let argv = args()
    if argv.len() < 2:
        print("usage: migrate_d22_copy_views <candidate-with> [source.w] [--apply]")
        exit_code(2)
    let candidate = argv.get(1)
    var source_path = "src/main.w"
    var apply = false
    for ai in 2..argv.len() as i32:
        let arg = argv[ai]
        if arg == "--apply":
            apply = true
        else if source_path == "src/main.w":
            source_path = arg
        else:
            print("usage: migrate_d22_copy_views <candidate-with> [source.w] [--apply]")
            exit_code(2)
    let out_path = "/tmp/with-d22-migrate.stdout"
    let err_path = "/tmp/with-d22-migrate.stderr"
    let encoded = candidate ++ "\0check\0" ++ source_path ++ "\0"
    let rc = unsafe { with_exec_argv_capture(encoded, out_path, err_path, 180000) }
    if rc == 0:
        print(f"D22 migration: candidate already accepts {source_path}")
        return
    let diagnostics = unsafe { with_fs_read_file(err_path) }
    let edits = parse_diagnostics(diagnostics)
    if edits.paths.len() == 0:
        print("error: candidate failed but supplied no actionable D22 Copy-view diagnostics")
        exit_code(1)
    var failures = 0
    for i in 0..edits.paths.len() as i32:
        if apply_one(edits.paths.get(i as i64), edits.lines.get(i as i64), edits.names.get(i as i64), edits.types.get(i as i64), apply) < 0:
            failures = failures + 1
    print(f"D22 migration: {edits.paths.len()} proven binding(s), failures={failures}")
    if failures != 0: exit_code(1)
