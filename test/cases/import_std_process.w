// Test: std.process import
use std.process

fn main -> i32:
    let p = pid()
    // PID should be positive
    assert(p > 0)

    let argv = args()
    assert(argv.len() >= 0)

    assert(set_env("WITH_STD_PROCESS_TEST", "ok") == 0)
    let ev = env("WITH_STD_PROCESS_TEST")
    assert(ev.is_some())
    assert(ev.unwrap() == "ok")

    let missing = env("__WITH_STD_PROCESS_MISSING__")
    assert(missing.is_none())

    assert(system_cmd("true") == 0)
    let cmd = command("true")
    assert(cmd.run() == 0)
    assert(cmd.status() == 0)
