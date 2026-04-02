//! expect-stdout: ok

async fn slow() -> i32:
    100

async fn fast() -> i32:
    42

async fn main:
    let t1 = slow()
    let t2 = fast()
    // select cancels the loser
    select await:
        r = t2 => assert(r == 42)
        s = t1 => assert(s == 100)
    print("ok")
