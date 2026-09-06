//! expect-stdout: ok
// #1081: the runner launches every test binary by a relative path with
// forward slashes (out/test/behavior/<stem>.test.<pid>.<nanos>), and so do
// `with run` and `with -e` for the binaries they build. Windows'
// CreateProcessW does not resolve such a path from the command line
// (ERROR_FILE_NOT_FOUND); the spawner now spells argv[0] with backslashes.
// This fixture re-launches its own binary once by exactly that spelling:
// args()[0] is the path the runner used.
use std.process

fn main:
    if env("WITH_BEHAV_RELATIVE_CHILD") == "1":
        return
    assert(set_env("WITH_BEHAV_RELATIVE_CHILD", "1") == 0)
    let argv = args()
    var child: Vec[str] = Vec.new()
    child.push(argv[0] ++ "")
    let rc = run(&child)
    assert(rc == 0)
    print("ok")
