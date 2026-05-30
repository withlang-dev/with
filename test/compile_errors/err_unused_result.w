//! expect-error: E0802

fn fallible() -> Result[i32, str]: Ok(1)

fn f() -> Result[i32, str]:
    fallible()
    Ok(0)
