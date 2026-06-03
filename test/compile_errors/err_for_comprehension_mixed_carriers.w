//! expect-check-fail: non-exhaustive match: missing variant 'Ok'

fn main:
    let result = for a in Some(2); b in Ok(3):
        yield a + b
    let _ = result
