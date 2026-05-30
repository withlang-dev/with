//! expect-error: E0802

fn fallible() -> Result[i32, str]: Ok(1)

fn f() -> Unit:
    fallible()
