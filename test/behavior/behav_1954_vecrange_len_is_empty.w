//! expect-stdout: 2 false
//! expect-stdout: 0 true
//! expect-stdout: 3 false

// #1954: `len()` and `is_empty()` on a VecRange, from `v.range(start..end)`,
// build and run; a range the wrong shape is a Sema error
// (test/compile_errors/err_1954_vec_range_two_args.w), never a crash.

fn main:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    let r = v.range(0..2)
    print(f"{r.len()} {r.is_empty()}")
    let e = v.range(1..1)
    print(f"{e.len()} {e.is_empty()}")
    let all = v.range(0..3)
    print(f"{all.len()} {all.is_empty()}")
