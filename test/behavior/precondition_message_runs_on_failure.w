//! expect-stdout: message evaluated
//! expect-exit: 134
//! expect-stderr: require failed: 7

// D86 (§18.2, #1864): on failure the message operand is evaluated, once,
// after the condition, and the form panics with it.

fn message(n: i32) -> str:
    print("message evaluated")
    f"require failed: {n}"

fn main:
    let n = 7
    require(n < 0, message(n))
    print("unreachable")
