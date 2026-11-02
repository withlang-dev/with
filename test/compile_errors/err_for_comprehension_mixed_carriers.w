//! expect-check-fail: for-comprehension clauses must use the same carrier family

fn main:
    let result = [a + b for a in Some(2) for b in Ok(3)]
    let _ = result
