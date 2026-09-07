use BuildGraphRuntime

let sandbox = ".audit/probes/build_graph_runtime_sandbox"
let data_path = sandbox ++ "/data.txt"
let empty_path = sandbox ++ "/empty.txt"

assert(build_graph_rt_mkdir_p(sandbox) == 0)
assert(build_graph_rt_write_file(data_path, "payload") == 0)
assert(build_graph_rt_read_file(data_path) == "payload")
assert(build_graph_rt_write_file(empty_path, "") == 0)
assert(build_graph_rt_read_file(empty_path).len() == 0)
assert(build_graph_rt_file_exists(data_path) == 1)
assert(build_graph_rt_is_dir(sandbox) == 1)
assert(build_graph_rt_getpid() > 0)
assert(build_graph_rt_cpu_cores() > 0)

let directory_read = build_graph_rt_read_file(sandbox)
let missing_read = build_graph_rt_read_file(sandbox ++ "/missing")
let failed_write_rc = build_graph_rt_write_file("/dev/full", "payload")

print(f"directory-read-len={directory_read.len()} missing-read-len={missing_read.len()} failed-write-rc={failed_write_rc}")
assert(directory_read.len() == 0)
assert(missing_read.len() == 0)
assert(failed_write_rc == 0)
