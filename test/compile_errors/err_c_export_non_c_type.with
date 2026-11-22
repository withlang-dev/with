//! expect-error: not C-ABI-expressible

// §16.5: a @[c_export] function with a non-C type silently miscompiles its
// ABI today; it must be a loud error at the declaration.

@[c_export("export_str")]
fn export_str(s: str) -> i32:
    0

fn main:
    print("x")
