//! expect-error: range() expects a range argument, `v.range(start..end)`, found i32

// #1954: one argument that is not a range is refused the same way.

fn main:
    var v: List[i32] = List.new()
    v.push(1)
    let n: i32 = 1
    let r = v.range(n)
    print(f"{r.len()}")
