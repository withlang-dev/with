//! expect-stdout: ok

// §16.3c, D47: a c_imported `const char *` parameter accepts a `str`. The rule
// has no condition on the function's other parameters: `strtol` takes a
// `char **` out-parameter, so the call is raw and needs `unsafe`, and its text
// argument is still lent. It used to be refused ("expects *const i8") as soon
// as any other parameter was a raw pointer, which sent every real C API
// (sqlite3_open, sqlite3_prepare_v2) back to `c"...".ptr` and CString.
use c_import("long strtol(const char *s, char **end, int base);\n")

fn main:
    assert(unsafe { strtol("42", null, 10) } == 42)
    let text = f"{4}{1}"
    assert(unsafe { strtol(text, null, 10) } == 41)
    var end: *mut i8 = null
    assert(unsafe { strtol("7x", &raw mut end, 10) } == 7)
    assert(unsafe { *end } == 'x' as i8)
    print("ok")
