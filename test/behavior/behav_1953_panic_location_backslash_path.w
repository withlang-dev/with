//! only-on: windows
//! expect-stdout: ok

// A panic location prints the source path byte for byte (#1953). The
// compiler synthesized `path:line:col` as a plain string constant, and the
// backends decode a plain constant's escapes as they do a source literal's,
// so `W:\review\test\b.w` printed as `W:` CR `eview` TAB `estb.w`. The
// program under test lives at a path whose separators spell `\t`, `\r` and
// `\b`; its own `__FILE__` takes the same route.
use std.fs
use std.process

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let temp = env("TEMP")
    assert(temp.len() > 0)
    let base = temp ++ f"\\with-behav-1953-{pid()}"
    let _clean = remove_tree(base)
    let dir = base ++ "\\t\\r\\b"
    assert(mkdir_p(dir) == 0)
    let src = dir ++ "\\boom.w"
    assert(write_file(src, "fn main:\n    print(__FILE__)\n    panic(\"boom\")\n") == 0)
    let stdout_path = base ++ "\\stdout"
    let stderr_path = base ++ "\\stderr"
    let ran = run_to_files(&[compiler, "run", src], stdout_path, stderr_path, 120000)
    assert(not ran.timed_out)
    let out = read_file(stdout_path).unwrap()
    let err = read_file(stderr_path).unwrap()
    if out != src ++ "\n" or not err.contains("panic at " ++ src ++ ":3:5: boom"):
        print("stdout: " ++ out)
        print("stderr: " ++ err)
        exit_code(1)
    assert(remove_tree(base) == 0)
    print("ok")
