//! expect-stdout: ok
// #977 (§16.1, D155): C's `long double` is a double only on macOS AArch64
// and Windows. The one predicate c_import and Sema both read.
use TargetSpec

fn main:
    assert(c_long_double_is_double("Macos", "aarch64"))
    assert(c_long_double_is_double("Windows", "x86_64"))
    assert(c_long_double_is_double("Windows", "aarch64"))
    assert(not c_long_double_is_double("Linux", "x86_64"))
    assert(not c_long_double_is_double("Linux", "aarch64"))
    assert(not c_long_double_is_double("Wasi", "wasm32"))
    print("ok")
