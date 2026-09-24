//! expect-stdout: ok

// D51 stage 7 (ruling §33, §41; spec §16.2b.7-8): `getenv` is an item of
// the toolchain libc facade — `returns borrow CStr from domain environ` —
// so the call is safe and its result is `Option[CStr]`: a missing variable
// is `None`, never a null pointer. (Until stage 7 this was the #379
// overlay's raw, natively nullable pointer.)

use c_import("char *getenv(const char *name);\n")

fn main:
    let v = getenv("WITH_DEFINITELY_ABSENT_VAR_XYZZY_379")
    if v.is_none():
        print("ok")
    else:
        print("bad")
