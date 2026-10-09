fn main:
    let values: List[i32] = List.new()
    assert(values.is_empty())
    values.push(1)
    assert(not values.is_empty())
