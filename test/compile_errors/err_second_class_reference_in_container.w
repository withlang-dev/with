//! expect-check-fail: ephemeral references cannot be stored in generic containers

fn bad:
    let x = 42
    var refs: Vec[&i32] = Vec.new()
    refs.push(&x)
