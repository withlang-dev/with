//! expect-stdout: ok

// docs/mut.md Rev 8 §15.8 — the iter-of-self mechanism only triggers a
// borrow conflict when the iterator's receiver place overlaps with the
// closure's mutable capture. Independent values (xs.len() returns i64 by
// value, no retained access) leave the closure free to mutate xs.

fn fancy(n: i64, cb: fn(i32) -> i32) -> i32:
    cb(n as i32)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let n = fancy(xs.len(), item => xs.push(item))
    let _ = n
    print("ok")
