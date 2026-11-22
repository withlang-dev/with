//! expect-stdout: message evaluated
//! expect-exit: 134
//! expect-stderr: assert failed

// D86 (§18.2, #1864): `assert` evaluates its message only on failure.

fn message() -> str:
    print("message evaluated")
    "assert failed"

fn main:
    assert(1 + 1 == 3, message())
    print("unreachable")
