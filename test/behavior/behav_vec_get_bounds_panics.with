//! expect-exit: 134
//! expect-stderr: index out of bounds

// D71: `xs[i]` is the one element spelling on a List, and out of range it
// panics like the array and slice index (behav_array_index_bounds_panics).
fn main:
    let values: List[i32] = List.new()
    values.push(1)
    let _ = values[1]
