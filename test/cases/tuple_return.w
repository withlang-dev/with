// Test returning tuples from functions
fn divmod(a: i32, b: i32) -> (i32, i32) =
    (a / b, a % b)

fn main() -> i32 =
    let (q, r) = divmod(17, 5)
    println(q)
    println(r)
    let (q2, r2) = divmod(100, 7)
    println(q2)
    println(r2)
    0
