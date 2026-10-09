//! expect-debug-alloc: leak count=0

fn main:
    let values: List[i64] = List.new()
    values.push(7)
    values.push(9)
    let wrapped: Option[List[i64]] = Some(move values)
    let owned = wrapped.unwrap()
    assert(owned.len() == 2)
