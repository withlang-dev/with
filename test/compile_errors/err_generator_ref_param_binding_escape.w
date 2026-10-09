//! expect-check-fail: generator captures reference to 'values' that cannot escape

gen fn values_from(source: &List[i32]) -> i32:
    yield source.len() as i32

fn bad:
    let values: List[i32] = [1, 2, 3]
    let iter = values_from(&values)
    return iter
