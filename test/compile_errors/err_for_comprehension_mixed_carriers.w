//! expect-check-fail: for-comprehension clauses must use the same carrier family

fn main:
    let result = for a in Some(2); b in Ok(3):
        yield a + b
    let _ = result
