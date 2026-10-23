//! expect-stdout: ok

// #2570 (§2.5.1): a cancellation unwind between a call's argument
// evaluations must not reset an argument temporary whose move has not
// happened; the ownership audit read "reset of _1 on a path where it was
// never moved". The move operand is recorded with the pending reset and
// the reset is emitted only once the move has been.
use pre_d_build_runner

fn program_text -> str:
    "use std.time\n" ++
        "use std.builtins.print_i32\n" ++
        "fn sleeper() -> i32:\n" ++
        "    sleep(1).await\n" ++
        "    1\n" ++
        "fn a(f: fn() -> i32) -> fn() -> i32:\n" ++
        "    let _ = f()\n" ++
        "    f\n" ++
        "fn use3(x: fn() -> i32, y: fn() -> i32, z: fn() -> i32) -> i32: x() + y() + z()\n" ++
        "fn main: print_i32(use3(a(sleeper), a(sleeper), a(sleeper)))\n"

fn main:
    let case_dir = p7_prepare_case("unwind_before_argument_move", "unwind_before_argument_move")
    p7_write(case_dir, "src/args.w", program_text())
    let ran = p7_run(case_dir, "args_run", "run\0src/args.w\0")
    p7_assert_success(ran, "argument calls that poll run")
    assert(ran.stdout.contains("3"))
    let audited = p7_run(case_dir, "args_audit", "analyze\0src/args.w\0audit:all\0")
    p7_assert_success(audited, "audit:all over polled argument calls")
    assert(audited.stdout.contains("violations=0"))
    print("ok")
