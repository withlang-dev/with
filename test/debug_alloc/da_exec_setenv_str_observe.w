//! expect-debug-alloc: leak count=0

// #747: with_exec_* / with_setenv_str observe their &str arguments. The
// interim rt_compat_* consuming signatures freed the caller's buffer in the
// callee epilogue (the `with run` bin_path UAF): a fresh argv blob was freed
// twice, and borrowed name/value buffers were freed while live. Arguments
// must remain intact and owned by the caller after the call.
use std.process

fn main:
    let program = "/usr/bin/true".to_owned()
    let argv: List[str] = List.new()
    argv.push(program.slice(0, program.len()))
    let rc = run(&argv)
    assert(rc == 0)
    let _e = set_env("WITH_DA_EXEC_REUSE", program)
    print(program)
