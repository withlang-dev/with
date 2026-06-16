//! expect-error: undefined variable

// A function guarded for a non-active architecture is excluded entirely;
// referencing it fails loudly rather than producing wrong-target code.
// (aarch64 host assumed.)

@[target("x86_64")]
fn only_on_x86() -> i32:
    1

fn main:
    let r = only_on_x86()
    print("x")
