//! expect-check-fail: copy `home` out (`to_owned()`) before the call
//! expect-check-fail: = help: describe setenv with an fn item in a facade and state `preserves domain environ` if it leaves that storage valid, or copy `home` out (`to_owned()`) before the call

// D208 (§16.2b.7): the toolchain's libc contract names the functions that
// rewrite the environment. A view from `getenv` dies at a call of one of
// them, here `setenv`: POSIX.1-2024 has the pointer `getenv` returns point
// into the environment data, which `setenv` may move or free. The accepted
// spelling copies the value out before the call.

use c_import("char *getenv(const char *name);\nint setenv(const char *name, const char *value, int overwrite);\n")

fn main:
    let home = getenv("HOME").unwrap()
    let rc = unsafe { setenv("WITH_3127_PROBE", "1", 1) }
    print(f"home: {home.to_str().unwrap()} {rc}")
