//! expect-stdout: two values: true true
//! expect-stdout: ok

// C11 7.22.4.6p4: a second `getenv` may overwrite the text the first
// returned, so the toolchain libc facade does not state `preserves domain
// environ` on it, and holding the first view across the second call is
// refused (err_c_facade_getenv_view_invalidated). An application copies the
// first out — `to_owned()` — and then reads the second: the way the
// standard says the program must be written, spelled once.

use c_import("char *getenv(const char *name);\n")

fn main:
    let home = getenv("HOME").map(v => v.to_owned())
    let path = getenv("PATH")
    print(f"two values: {home.is_some()} {path.is_some()}")
    print("ok")
