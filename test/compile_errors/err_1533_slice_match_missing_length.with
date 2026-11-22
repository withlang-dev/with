//! expect-check-fail: `[_, _]` is not covered

// #1533: the witness names the uncovered length.

fn f(s: []i32) -> i32:
    match s:
        [] => 0
        [a] => a
        [a, _, _, ..] => a

fn main:
    let a: [i32; 2] = [1, 2]
    print(f(a[..]))
