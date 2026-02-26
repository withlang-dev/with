// Test: multiple async tasks running concurrently
async fn add(a: i32, b: i32) -> i32:
    a + b

async fn multiply(a: i32, b: i32) -> i32:
    a * b

fn main -> i32:
    // Spawn multiple tasks
    let t1 = add(10, 20)
    let t2 = multiply(5, 6)
    let t3 = add(100, 200)

    // Await results
    let r1 = t1.await
    let r2 = t2.await
    let r3 = t3.await

    assert(r1 == 30)
    assert(r2 == 30)
    assert(r3 == 300)
