//! expect-error: `check` is a compiler-known form, not a function

// D86 (§18.2, #1864): `check` is not a function: it cannot be passed where
// a function value is expected.
fn run(f: fn(bool, &str, &str) -> Unit):
    f(true, "message", "here")

fn main:
    run(check)
