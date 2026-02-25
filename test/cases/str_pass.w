extern fn puts(s: *const i8) -> i32

fn main() -> i32 =
    let s: str = "Hello!"
    puts(s)
    0
