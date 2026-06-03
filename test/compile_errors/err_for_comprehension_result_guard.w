//! expect-check-fail: Result for-comprehension guards are not allowed

fn main:
    let result: Result[i32, str] = for a in Ok(2); if a > 0:
        yield a + 1
    let _ = result
