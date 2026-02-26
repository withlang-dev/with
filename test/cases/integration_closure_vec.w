// Integration test: closures with vector iteration
fn for_each(v: Vec[i32], f: fn(i32) -> void) -> void =
    for x in v
        f(x)

fn print_val(x: i32) -> void =
    println(x)

fn main() -> i32 =
    var v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    for_each(v, print_val)
    0
