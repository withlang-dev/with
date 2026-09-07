use BuildGraphRuntime

// New-ABI wrappers (catch-up delta 31f77937..450733e5: try_wait, maxrss).
// Blocked until the stage1 binary embeds runtime objects built from the new
// tree: with the stale stage1 this fails at LINK (undefined
// with_exec_try_wait / with_exec_child_maxrss / with_self_maxrss), which is
// toolchain staleness, not a module defect.

let sandbox = ".audit/probes/build_graph_runtime_sandbox3"
let out_path = sandbox ++ "/out.txt"
let err_path = sandbox ++ "/err.txt"

assert(build_graph_rt_mkdir_p(sandbox) == 0)
assert(build_graph_rt_self_maxrss() > 0)
let pid = build_graph_rt_exec_argv_capture_spawn("/bin/sleep\05\0", out_path, err_path)
assert(pid > 0)
assert(build_graph_rt_exec_try_wait(pid) == -2)
assert(build_graph_rt_exec_wait(pid, 30000) == 0)
assert(build_graph_rt_child_maxrss() >= 0)

assert(build_graph_rt_remove_file(out_path) == 0)
assert(build_graph_rt_remove_file(err_path) == 0)
assert(build_graph_rt_remove_tree(sandbox) == 0)
assert(build_graph_rt_file_exists(sandbox) == 0)

print("new-abi-ok")
