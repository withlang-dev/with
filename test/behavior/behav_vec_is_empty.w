fn main:
    let values: Vec[i32] = Vec.new()
    assert(values.is_empty())
    values.push(1)
    assert(not values.is_empty())
