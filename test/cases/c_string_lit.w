// Test c-string literals (null-terminated)

extern fn puts(s: *const i8) -> i32

fn main() -> i32 =
    // c"..." produces a *const i8 (null-terminated C string)
    let msg = c"hello from c-string"
    puts(msg)
    0
