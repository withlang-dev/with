use BuildGraphModel
use BuildGraphOps

extern fn with_fs_mkdir_p(path: &str) -> i32
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_fs_file_exists(path: &str) -> i32

fn mkdir(path: &str) -> i32: unsafe { with_fs_mkdir_p(path) }
fn write_file(path: &str, data: &str) -> i32: unsafe { with_fs_write_file(path, data) }
fn file_exists(path: &str) -> i32: unsafe { with_fs_file_exists(path) }

let sandbox = ".audit/probes/build_graph_ops_clean_sandbox"
let marker = sandbox ++ "/keep.txt"
assert(mkdir(sandbox) == 0)
assert(write_file(marker, "must survive") == 0)

var target = empty_build_graph_target()
target.name = "clean-root"
target.args.push(".")
let rc = build_graph_run_clean(sandbox, &target)
assert(file_exists(marker) == 0)
print(f"clean-root rc={rc} marker-removed")
