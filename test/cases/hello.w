extern fn puts(s: *const i8) -> i32

fn main() -> i32 =
    puts("Hello, World!")
    0
