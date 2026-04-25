//! skip
// Spec test: Section 16 — FFI and `c_import` (formerly 25.11)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: c_import makes C functions callable directly
use c_import("stdio.h")
fn test:
    printf(c"hello %d\n".ptr, 42)             // no unsafe needed

// PASS: c_import with link directive
use c_import("sqlite3.h", link: "sqlite3")
fn test:
    var db: *mut sqlite3 = null
    let rc = sqlite3_open(c":memory:".ptr, &mut db)  // direct call
    assert(rc == SQLITE_OK)
    sqlite3_close(db)

// PASS: c_import structs are usable
use c_import("time.h")
fn test:
    var t: time_t = 0
    time(&mut t)                               // direct call

// PASS: extern C manual declaration
extern "C" { fn puts(s: *const u8) -> i32 }
fn test: puts(c"hello".ptr)

// PASS: non-capturing closure to fn ptr
fn test:
    let f: extern "C" fn(i32) -> i32 = x => x + 1

// FAIL: capturing closure to fn ptr
fn test:
    let offset = 5
    let f: extern "C" fn(i32) -> i32 = x => x + offset  // ERROR

// PASS: c_import constants available
use c_import("limits.h")
fn test:
    assert(PATH_MAX > 0)
    assert(INT_MAX == 2147483647)
