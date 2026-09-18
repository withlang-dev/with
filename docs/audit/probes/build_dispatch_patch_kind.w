extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32

let path = "/home/shawn/workspace2/with/.audit/probes/build_dispatch_unknown_kind/out/.build-state/build-graph.cache"
let before = with_fs_read_file(path)
let old = "i 0 0 0 0 0 0 0\n"
let replacement = "i 999 0 0 0 0 0 0\n"
let after = before.replace(old, replacement)
assert(after != before)
assert(with_fs_write_file(path, after) == 0)
