//! expect-build-fail: invalid MIR before codegen: unsupported cast in MIR

// Test: invalid cast from str to i32 is rejected at code generation.

fn main:
    let s = "hello"
    let x = s as i32
    print(int_to_string(x))
