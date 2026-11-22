//! expect-stdout: ok

var seen: i32 = 0

async fn inner_slow() -> i32:
    defer: unsafe { seen = seen + 1 }
    5

async fn inner_fast() -> i32:
    2

async fn outer() -> i32:
    let a = inner_slow()
    let b = inner_fast()
    select await:
        x = b => assert(x == 2)
        y = a => assert(y == 5)
    unsafe { assert(seen == 1) }
    9

async fn main:
    unsafe { seen = 0 }
    let t = outer()
    assert(t.await == 9)
    unsafe { assert(seen == 1) }
    print("ok")
