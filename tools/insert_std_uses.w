// Insert `use` lines selected by live compiler diagnostics (D29 #750 scaffolding).
// Sema owns the gate decision and the exact insertable line ("… add: use M.N");
// this tool parses saved diagnostic output and applies header edits per file.
// Dry-run is the default.
//
//   with-stage1 check <entry.w> 2> diags.txt
//   with run tools/insert_std_uses.w [--apply] diags.txt
//
// Diagnostics must come from a gate-aware compiler (stage1+); loop until clean.
// (Reads a saved file, not the live analyze API, so the tool itself never
// depends on compiling the entry it is repairing.)
use std.process

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32

fn source_path(path: str) -> str:
    let embedded = "<embedded-std>/"
    if path.starts_with(embedded): "lib/" ++ path.slice(embedded.len(), path.len()) else: path

fn gate_use_line(message: str) -> str:
    let parts = message.split("; add: use ")
    if parts.len() < 2: return ""
    "use " ++ parts.get(1)

fn diag_path(loc_line: str) -> str:
    // " --> src/Foo.w:74:17" → "src/Foo.w"
    let parts = loc_line.split("--> ")
    if parts.len() < 2: return ""
    let with_pos = parts.get(1)
    var cut = with_pos.len()
    var colons = 0
    var i = with_pos.len() - 1
    while i >= 0 and colons < 2:
        if with_pos[i] == 58:
            colons = colons + 1
            cut = i
        i = i - 1
    with_pos.slice(0, cut)

fn header_insert_offset(text: str) -> i64:
    // After the last `use` line in the leading header (comments/blank/use).
    var last_use_end = -1 as i64
    var line_start = 0 as i64
    let n = text.len()
    while line_start < n:
        var line_end = line_start
        while line_end < n and text[line_end] != 10:
            line_end = line_end + 1
        let line = text.slice(line_start, line_end)
        if line.starts_with("use ") or line.starts_with("module "):
            last_use_end = line_end + 1
        else if line.len() > 0 and not line.starts_with("//") and not line.starts_with("#!"):
            break
        line_start = line_end + 1
    if last_use_end >= 0: last_use_end else: line_start

fn vec_contains(v: &Vec[str], s: str) -> bool:
    for i in 0..v.len():
        if v.get(i) == s: return true
    false

let argv = args()
var apply = false
var diags_file = ""
for i in 1..argv.len():
    let a = argv.get(i)
    if a == "--apply": apply = true
    else: diags_file = a
if diags_file.len() == 0:
    eprint("usage: insert_std_uses [--apply] <diagnostics.txt>")
    exit_code(2)

let diags = with_fs_read_file(diags_file)
var pair_paths: Vec[str] = Vec.new()
var pair_lines: Vec[str] = Vec.new()
var pending_use = ""
var gate_count = 0
for line in diags.split("\n"):
    if line.starts_with("error: "):
        pending_use = gate_use_line(line)
        continue
    if pending_use.len() > 0 and line.contains("--> "):
        let path = source_path(diag_path(line))
        if path.len() > 0:
            gate_count = gate_count + 1
            var seen = false
            for pi in 0..pair_paths.len() as i32:
                if pair_paths[pi] == path and pair_lines[pi] == pending_use:
                    seen = true
                    break
            if not seen:
                pair_paths.push(path)
                pair_lines.push(pending_use)
        pending_use = ""

print(f"insert-std-uses: {gate_count} gate diagnostics, {pair_paths.len() as i32} distinct (file, use) pairs")
var done_paths: Vec[str] = Vec.new()
for fi in 0..pair_paths.len() as i32:
    let path = pair_paths[fi]
    if vec_contains(&done_paths, path):
        continue
    done_paths.push(path)
    var block = ""
    for li in 0..pair_paths.len() as i32:
        if pair_paths[li] == path:
            block = block ++ pair_lines[li] ++ "\n"
    if not apply:
        for line in block.split("\n"):
            if line.len() > 0: print(path ++ ": " ++ line)
        continue
    let text = with_fs_read_file(path)
    if text.len() == 0:
        eprint("insert-std-uses: cannot read " ++ path)
        exit_code(1)
    // Skip lines the file already has (idempotent across passes).
    var to_insert = ""
    for line in block.split("\n"):
        if line.len() > 0 and not ("\n" ++ text).contains("\n" ++ line ++ "\n"):
            to_insert = to_insert ++ line ++ "\n"
    if to_insert.len() == 0:
        continue
    let at = header_insert_offset(text)
    let updated = text.slice(0, at) ++ to_insert ++ text.slice(at, text.len())
    if with_fs_write_file(path, updated) != 0:
        eprint("insert-std-uses: cannot write " ++ path)
        exit_code(1)
    for line in to_insert.split("\n"):
        if line.len() > 0: print("inserted " ++ path ++ ": " ++ line)
