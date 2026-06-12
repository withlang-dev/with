extern fn with_print_str(s: str) -> Unit

fn main:
    unsafe { with_print_str("hello\n") }
