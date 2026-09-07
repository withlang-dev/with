use BuildGraphRuntime

let sandbox = ".audit/probes/build_graph_runtime_sandbox2"
let out_path = sandbox ++ "/out.txt"
let err_path = sandbox ++ "/err.txt"
let f1 = sandbox ++ "/f1.txt"
let f2 = sandbox ++ "/f2.txt"
let link = sandbox ++ "/link.txt"
let sub = sandbox ++ "/sub"

// env round-trip through the facade
assert(build_graph_rt_setenv("WITH_AUDIT_RUNTIME_PROBE", "present") == 0)
assert(build_graph_rt_getenv("WITH_AUDIT_RUNTIME_PROBE") == "present")
assert(build_graph_rt_getenv("WITH_AUDIT_RUNTIME_PROBE_MISSING") == "")

// mkdir + write + mode + chmod
assert(build_graph_rt_mkdir_p(sub) == 0)
assert(build_graph_rt_write_file(f1, "hello") == 0)
assert(build_graph_rt_file_mode(f1) != 0)
assert(build_graph_rt_chmod(f1, 0o600) == 0)

// list + rename + readlink + remove
assert(build_graph_rt_list_files(sandbox).contains("f1.txt") == true)
assert(build_graph_rt_rename_file(f1, f2) == 0)
assert(build_graph_rt_file_exists(f1) == 0)
assert(build_graph_rt_read_file(f2) == "hello")
assert(build_graph_rt_exec_argv_capture("/bin/ln\0-s\0f2.txt\0" ++ link ++ "\0", out_path, err_path, 30000) == 0)
assert(build_graph_rt_readlink(link).contains("f2.txt") == true)

// exec capture: exit codes and captured stdout
assert(build_graph_rt_exec_argv_capture("/bin/true\0", out_path, err_path, 30000) == 0)
assert(build_graph_rt_exec_argv_capture("/bin/false\0", out_path, err_path, 30000) != 0)
assert(build_graph_rt_exec_argv_capture_cwd("/bin/pwd\0", out_path, err_path, 30000, sub) == 0)
assert(build_graph_rt_read_file(out_path).contains("sandbox2") == true)

// clock and args
assert(build_graph_rt_clock_nanos() > 0)
assert(build_graph_rt_arg_at(-1) == "")
assert(build_graph_rt_usleep(1000) == 0)

// teardown through the facade
assert(build_graph_rt_remove_file(f2) == 0)
assert(build_graph_rt_remove_file(link) == 0)
assert(build_graph_rt_remove_file(out_path) == 0)
assert(build_graph_rt_remove_file(err_path) == 0)
assert(build_graph_rt_remove_dir(sub) == 0)
assert(build_graph_rt_is_dir(sub) == 0)
assert(build_graph_rt_remove_tree(sandbox) == 0)
assert(build_graph_rt_file_exists(sandbox) == 0)

print("wrappers-ok")
