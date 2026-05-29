//! expect-check-fail: ? operator not allowed in defer

fn bad_question -> Result[i32, str]:
    let cleanup: Result[i32, str] = Ok(1)
    defer:
        cleanup?
    Ok(2)
