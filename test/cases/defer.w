extern fn puts(s: *const i8) -> i32

fn main() -> i32 =
    defer puts("deferred!")
    let x = 42
    x
