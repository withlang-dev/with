//! expect-check-fail: copy `home` out (`to_owned()`) before the call

// C11 7.22.4.6p4: the string `getenv` returns "may be overwritten by a
// subsequent call to the getenv function". The toolchain libc facade
// (compiler/LibcFacade.w) therefore states no `preserves domain environ`
// on `getenv`: a second call invalidates the view the first returned
// (ruling §38: unknown effect means invalidate). The accepted spelling
// copies the first out before the second call — behav_c_facade_getenv_twice.

use c_import("char *getenv(const char *name);\n")

fn main:
    let home = getenv("HOME").unwrap()
    let path = getenv("PATH")
    print(f"home: {home.to_str().unwrap()} {path.is_some()}")
