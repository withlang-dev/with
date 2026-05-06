//! expect-stdout: ok

@[tailrec]
fn a(n: i32) -> i32:
    if n <= 0: 0
    else: b(n - 1)

@[tailrec]
fn b(n: i32) -> i32:
    if n <= 0: 0
    else: c(n - 1)

@[tailrec]
fn c(n: i32) -> i32:
    if n <= 0: 0
    else: a(n - 1)

fn main:
    assert(a(0) == 0)
    assert(a(3) == 0)
    assert(b(4) == 0)
    assert(c(5) == 0)
    assert(a(100000) == 0)
    print("ok")
