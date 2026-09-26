//! expect-stdout: 3000000001
//! expect-stdout: 3000000001
//! expect-stdout: 3000000001
//! expect-stdout: 6000000000
//! expect-stdout: 3000000001
//! expect-stdout: true

// #1477: an unsuffixed literal next to a `&i64` view takes the pointee's
// type; the sum was computed at i32 and truncated.

fn f(p: &i64) -> i64: p + 1

fn main:
    let v: Vec[i64] = Vec.new()
    v.push(3000000000)
    let p = v[0]
    let q = p + 1
    print(q)
    print(f(3000000000))
    let r: i64 = v.get(0) + 1
    print(r)
    print(p * 2)
    let k: i32 = 1
    print(p + k)
    print(p > 1)
