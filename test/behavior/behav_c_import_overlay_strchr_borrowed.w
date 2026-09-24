//! expect-stdout: ok

// D51 stage 7 (ruling §31, §41; spec §16.2b.8): `strchr` is an item of the
// toolchain libc facade — `returns borrow CStr from param 0` — so the call
// is safe and its result is `Option[CStr]` borrowed from the string it was
// lent: `None` when absent, and the text from the hit onwards otherwise,
// read without `unsafe`. (Until stage 7 this was the #379 overlay's raw,
// natively nullable pointer, dereferenced in `unsafe`.)

use c_import("char *strchr(const char *s, int c);\n")

fn main:
    let hit = strchr("hello", 'l')
    let miss = strchr("hello", 'z')
    if miss.is_some():
        print("bad-miss")
        return
    match hit:
        None => print("bad-none")
        Some(t) => print(if t.to_str().unwrap() == "llo": "ok" else: "bad-char")
