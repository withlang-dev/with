//! expect-check-fail: wrong argument type in call to 'takes_void'
// §16: str/int do not auto-coerce to void* — even under unsafe.
use c_import("void takes_void(void *p);\n")
fn main:
    unsafe:
        takes_void("hello")
    print("x")
