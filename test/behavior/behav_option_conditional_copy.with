fn main:
    let values: List[i64] = List.new()
    values.push(7)
    let found: Option[&List[i64]] = Some(&values)
    let first = found.unwrap()
    assert(found.is_some())
    let second = found.unwrap()
    assert(first.len() == second.len())
