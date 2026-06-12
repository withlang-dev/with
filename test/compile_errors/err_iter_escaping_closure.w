//! expect-check-fail: escaping closure cannot capture ephemeral references

fn bad:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    let iter = xs.iter()
    let f = () => iter.next().unwrap_or(0)
    let _ = f()
