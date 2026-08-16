//! expect-error: undefined variable
//! requires-arch: x86_64

// Mirror of err_target_excluded_symbol_use.w for an x86_64 host: a function
// guarded for aarch64 is excluded entirely on x86_64, so referencing it fails
// loudly rather than producing wrong-target code.

@[target("aarch64")]
fn only_on_arm() -> i32:
    1

fn main:
    let r = only_on_arm()
    print("x")
