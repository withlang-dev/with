//! expect-stdout: ok

// §4.9, the spec's own `validate` example: a `Result[Unit, E]` body that ends
// after an early `return Err(...)` returns `Ok(())`. It was "missing return".
// (The closure spelling waits on #1230: a `fn(...) -> Result[Unit, E]` value
// cannot be called yet.)
error AgeError = Invalid(age: i32)

fn validate(age: i32) -> Result[Unit, AgeError]:
    if age < 0: return Err(.Invalid(age))
    if age > 150: return Err(.Invalid(age))

fn main:
    assert(validate(30).is_ok())
    assert(validate(-1).is_err() and validate(200).is_err())
    print("ok")
