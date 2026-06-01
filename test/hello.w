extern fn with_print_str(s: str) -> void

fn main:
    unsafe { with_print_str("hello\n") }
