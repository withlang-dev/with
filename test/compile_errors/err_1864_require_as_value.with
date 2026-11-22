//! expect-error: `require` is a compiler-known form, not a function

// D86 (§18.2, #1864): `require` evaluates its message only when its
// condition is false. A function value would evaluate the message before
// the call, so the form is called directly, never used as a value.
fn main:
    let f = require
    f(true, "message", "here")
