//! expect-stdout: ok

// #3166: a child spawned with a relative working directory sees PWD as
// that directory's real path, the same path getcwd reports. The spawner
// once set PWD to the string it was given, so `with get` run through
// `run_to_files_in("out/x", …)` rooted its project at `out/x` and told
// CMake to use a relative compiler path. The test program is its own
// child: run with `--child` it prints PWD and the current directory.

use std.fs
use std.os
use std.process

let argv = args()
if argv.len() > 1 and argv[1] == "--child":
    print("PWD=" ++ env("PWD"))
    print("cwd=" ++ current_dir())
    exit_code(0)

let here = current_dir()
let dir = f"out/behav_3166_{process_id()}"
assert(mkdir_p(dir) == 0)
let out_path = here ++ "/" ++ dir ++ "/child.out"
let err_path = here ++ "/" ++ dir ++ "/child.err"
// The child's program path is absolute whatever directory it starts in.
let absolute = argv[0].starts_with("/") or (argv[0].len() > 1 and argv[0].slice(1, 2) == ":")
let program = if absolute: argv[0] else: here ++ "/" ++ argv[0]
let finished = run_to_files_in(dir, &[program, "--child"], out_path, err_path)
assert(finished.code == 0)
let said = read_file(out_path) ?? ""
let lines = said.split("\n")
assert(lines.len() >= 2)
let pwd = lines[0].slice(4, lines[0].len())
let cwd = lines[1].slice(4, lines[1].len())
assert(pwd.starts_with("/"), "PWD is relative: " ++ pwd)
assert(pwd == cwd, "PWD " ++ pwd ++ " is not the directory " ++ cwd)
assert(pwd.ends_with(dir))
remove_tree(dir)
print("ok")
