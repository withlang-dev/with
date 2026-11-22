//! expect-stdout: ok

// #2647: with_self_exe names the running executable: every self-invocation
// (`__ld`, `__ar`, `with cc`, the runtime root) reads it. On Windows a bare
// argv[0] is the current directory's, as cmd runs it, before PATH.
use compiler.LldDriver
use compiler.Runtime

fn main:
    let me = with_self_exe()
    assert(me.len() > 0)
    assert(runtime_file_exists(me) != 0)
    print("ok")
