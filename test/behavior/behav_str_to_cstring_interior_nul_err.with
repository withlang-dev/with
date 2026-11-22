// §15.2/§16.3c: str.to_cstring() rejects an interior NUL by returning Err,
// never silently truncating. Exercises a Result[CString, _] Err path (the
// drop of which must not corrupt — see #601).

use std.string

fn test_to_cstring_rejects_interior_nul:
    let nul = "\0"
    let poisoned = "abc" ++ nul ++ "def"
    match poisoned.to_cstring():
        Ok(c) => assert(false)
        Err(e) => assert(true)

fn test_to_cstring_ok_without_nul:
    match "clean".to_cstring():
        Ok(c) => assert(c.len() == 5)
        Err(e) => assert(false)

fn test_to_cstring_err_then_alloc_is_safe:
    // An Err result is dropped, then a fresh CString is allocated — the
    // allocator must stay intact (#601 regression at the std API level).
    match "x\0y".to_cstring():
        Ok(c) => assert(false)
        Err(e) => assert(true)
    match "ok".to_cstring():
        Ok(c) => assert(c.len() == 2)
        Err(e) => assert(false)
