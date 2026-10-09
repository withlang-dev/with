//! expect-check-fail: ephemeral references cannot be stored in generic containers

fn bad:
    let x = 42
    var refs: List[&i32] = List.new()
    refs.push(&x)
