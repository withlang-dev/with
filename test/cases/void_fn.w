extern fn puts(s: *const i8) -> i32

fn greet:
    puts("hello from greet")

fn main -> i32:
    greet()
    0
