// Test: §5.4 nested mutating calls on the same place
//! expect-error: nested mutating calls on the same place

fn test_nested_mutating_rejected:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(xs.pop().unwrap())
