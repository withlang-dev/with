extern fn with_fs_read_file(path: &str) -> str
use std.collections.HashMap

let path = "src/MirLower.w"
let text = unsafe { with_fs_read_file(path) }
let seen: HashMap[str, i32] = HashMap.new()
let producer_fns: HashMap[str, i32] = HashMap.new()
let reader_fns: HashMap[str, i32] = HashMap.new()
var current_fn = "<top-level>"
var line_number = 0
var sites = 0
var producer_sites = 0
var reader_sites = 0

for line in text.split("\n"):
    line_number = line_number + 1
    if line.contains(" fn ") and line.contains("("):
        current_fn = line.split(" fn ").get(1).split("(").get(0)
    else if line.starts_with("fn ") and line.contains("("):
        current_fn = line.slice(3, line.len()).split("(").get(0)
    if line.contains("TermKind.TK_CALL"):
        sites = sites + 1
        seen.insert(current_fn.clone(), 1)
        if line.contains(".terminate(TermKind.TK_CALL"):
            producer_sites = producer_sites + 1
            producer_fns.insert(current_fn.clone(), 1)
            print(f"P\t{path}:{line_number}\t{current_fn.clone()}")
        else:
            reader_sites = reader_sites + 1
            reader_fns.insert(current_fn.clone(), 1)
            print(f"R\t{path}:{line_number}\t{current_fn.clone()}")

print(f"sites={sites} functions={seen.len()} producer_sites={producer_sites} producer_functions={producer_fns.len()} reader_sites={reader_sites} reader_functions={reader_fns.len()}")
