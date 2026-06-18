//! expect-stdout: ok

// #379: strchr is curated -- its `const char*` parameter is `cstr_in` and its
// pointer return is a borrowed, nullable handle. Calling strchr is therefore
// safe (no unsafe). The return is a raw, natively-nullable pointer: `== None`
// and `.unwrap()` work directly (the same way malloc's plain `*mut c_void`
// return does). The returned pointer is borrowed (non-owning), so dereferencing
// it stays `unsafe`.

use c_import("char *strchr(const char *s, int c);\n")

fn main:
    let hit = strchr("hello", 108)   // 'l' -> pointer into "hello"
    let miss = strchr("hello", 122)  // 'z' -> None
    if miss != None:
        print("bad-miss")
        return
    if hit == None:
        print("bad-none")
        return
    let p = hit.unwrap()
    let ch = unsafe { *p }
    if ch == 108:
        print("ok")
    else:
        print("bad-char")
