//! expect-stdout: ok

comptime:
    fn add(a: i32, b: i32) -> i32:
        a + b

    fn nested_mul(a: i32, b: i32) -> i32:
        a * b

    comptime:
        fn nested_answer() -> i32:
            nested_mul(6, 7)

fn main:
    assert(add(2, 3) == 5)
    assert(nested_answer() == 42)
    println("ok")
