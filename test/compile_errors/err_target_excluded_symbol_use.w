//! expect-error: undefined variable
//! requires-arch: aarch64

// A function guarded for a non-active architecture is excluded entirely;
// referencing it fails loudly rather than producing wrong-target code. On an
// aarch64 host the x86_64-guarded symbol is excluded, so the reference is
// undefined. (The mirror err_target_excluded_symbol_use_x86_64.w covers the
// x86_64 host with an aarch64-guarded symbol.)

@[target("x86_64")]
fn only_on_x86() -> i32:
    1

fn main:
    let r = only_on_x86()
    print("x")
