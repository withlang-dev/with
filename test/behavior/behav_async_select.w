//! expect-stdout: ok

async fn fast() -> i32:
    10

async fn slow() -> i32:
    20

async fn main:
    let t1 = fast()
    let t2 = slow()
    select await:
        r1 = t1 => assert(r1 == 10)
        r2 = t2 => assert(r2 == 20)
    print("ok")
