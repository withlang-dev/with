//! expect-error: range() expects exactly one range argument, `v.range(start..end)`

// #1954: `v.range(0, 1)` passed Sema with two integer arguments and the
// VEC_RANGE lowering read a Range field off an i64, crashing the compiler
// at build (check was silent). The method takes one range.

fn main:
    var v: List[i32] = List.new()
    v.push(1)
    v.push(2)
    let r = v.range(0, 1)
    print(f"{r.len()}")
