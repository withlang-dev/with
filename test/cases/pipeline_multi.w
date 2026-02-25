// Test: pipeline chains with multiple |> operations
fn double(x: i32) -> i32 = x * 2

fn increment(x: i32) -> i32 = x + 1

fn negate(x: i32) -> i32 = 0 - x

fn add(a: i32, b: i32) -> i32 = a + b

fn sub(a: i32, b: i32) -> i32 = a - b

fn main() -> i32 =
    // simple chain: 5 * 2 + 1 = 11
    let a = 5 |> double |> increment
    assert(a == 11)

    // longer chain: ((3 * 2) + 1) * 2 = 14
    let b = 3 |> double |> increment |> double
    assert(b == 14)

    // chain with partial application: 10 * 2 + 5 = 25
    let c = 10 |> double |> add(5)
    assert(c == 25)

    // chain with subtraction: (10 * 2) - 3 = 17
    let d = 10 |> double |> sub(3)
    assert(d == 17)

    // all together: ((2 + 1) * 2 + 1) * 2 = 14
    let e = 2 |> increment |> double |> increment |> double
    assert(e == 14)

    println("all pipeline multi tests passed")
    0
