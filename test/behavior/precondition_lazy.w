//! expect-stdout: ok

// D86 (§18.2, #1864): `assert`, `require` and `check` are compiler-known
// forms, not functions. The message operand is evaluated only when the
// condition is false: on success its effects do not run.

fn side_effect() -> str:
    print("SHOULD NOT PRINT")
    "message"

fn main:
    require(true, side_effect())
    check(true, side_effect())
    assert(true, side_effect())
    print("ok")
