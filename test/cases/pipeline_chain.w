// Test: pipeline chaining over bare and called functions
fn add(x: i32, y: i32) -> i32 =
    x + y

fn double(x: i32) -> i32 =
    x * 2

fn main() -> i32 =
    let v = 10 |> double |> add(5) |> double
    assert(v == 50)
    0
