extern fn printf(fmt: *const i8, ...) -> i32

fn main() -> i32 =
    printf("hello %d\n", 42)
    assert(42 == 42)
    0
