// Test: @[inline] and @[noinline] function attributes

@[inline]
fn square(x: i32) -> i32: x * x

@[noinline]
fn cube(x: i32) -> i32: x * x * x

fn main -> i32:
    println(square(5))
    println(cube(3))
    println(square(10) + cube(2))
