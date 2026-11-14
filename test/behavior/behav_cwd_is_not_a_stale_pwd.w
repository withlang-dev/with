//! expect-stdout: ok
//! skip-on: windows no /usr/bin/env there; cmd.exe sets no PWD
// The compiler's working directory is the one the process is in. It took
// $PWD whenever the variable was set, so a process started in a project
// with the variable left naming another directory (`env -C dir with build`,
// a launcher that sets the directory and not the variable) looked for the
// project there: "cannot open '/src/main.w'".
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("cwd_is_not_a_stale_pwd", "stalepwd")
    var args = p7_argv_append("", "PWD=/")
    args = p7_argv_append(args, p7_compiler_path())
    args = p7_argv_append(args, "build")
    let ran = p7_run_with_compiler("/usr/bin/env", root, "stale-pwd", args)
    p7_assert_success(ran, "with build in a project, with PWD naming another directory")
    assert(not (ran.stdout ++ ran.stderr).contains("cannot open"))
    print("ok")
