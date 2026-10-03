//! expect-stdout: cond
//! expect-stdout: message evaluated
//! expect-exit: 134
//! expect-stderr: check failed

// D86 (§18.2, #1864): the condition is evaluated first and once; the
// message only after it is false.

fn cond() -> bool:
    print("cond")
    false

fn message() -> str:
    print("message evaluated")
    "check failed"

fn main:
    check(cond(), message())
    print("unreachable")
