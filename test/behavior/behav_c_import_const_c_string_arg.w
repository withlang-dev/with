//! expect-stdout: ok

// #379: strlen is in the curated libc overlay, so its `const char*` parameter
// is modeled as a `cstr_in` NUL-terminated string input and a With `str`
// coerces without unsafe. This works through the overlay evidence, not the
// removed blanket `const char*`-as-cstring assumption.

use c_import("unsigned long strlen(const char *s);\n")

fn main:
    assert(strlen("hello") == 5usize)
    let s = f"abc{1}"
    assert(strlen(s) == 4usize)
    print("ok")
