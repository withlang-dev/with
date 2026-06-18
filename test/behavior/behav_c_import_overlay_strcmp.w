//! expect-stdout: ok

// #379: the curated libc overlay covers more than strlen. strcmp's two
// `const char*` parameters are both modeled as `cstr_in`, so With strs coerce
// without unsafe through the overlay evidence.

use c_import("int strcmp(const char *a, const char *b);\n")

fn main:
    if strcmp("abc", "abc") == 0 and strcmp("abc", "abd") != 0:
        print("ok")
    else:
        print("bad")
