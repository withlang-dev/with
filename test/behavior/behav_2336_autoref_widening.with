//! expect-stdout: -1 -2 3
//! expect-stdout: 200 7

// #2336 (§4.2.6, §3.8): a narrower integer auto-referenced at a user's `&T`
// parameter widens into the pointee, materialized as a temporary of the
// pointee's type; the callee never reads the narrower place at the wider
// width (`-1` arrived as 4294967295).
fn f(x: &i64) -> i64: *x
fn g(x: &i16) -> i16: *x
fn h(x: &isize) -> isize: *x

fn main:
    let a: i32 = -1
    let b: i32 = -2
    print(f"{f(a)} {f(b)} {f(3)}")
    let u: u8 = 200
    let n: i32 = 7
    print(f"{g(u)} {h(n)}")
