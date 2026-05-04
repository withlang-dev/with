//! expect-run-output: "3\n2\n1\n"

extern fn with_write(s: str) -> void

fn main:
    defer: with_write("1\n")
    defer:
        with_write("2\n")
    defer {
        with_write("3\n")
    }
