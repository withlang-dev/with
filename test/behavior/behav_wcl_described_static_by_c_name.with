//! expect-stdout: 1.2.3

// §31.4: a function a contract names is described and has the meaning the
// contract gives it. `returns static CStr` covers the return, so a call by
// the C name in safe code is safe and yields the text, not a raw pointer.
use c_import("static inline const char *lib_version(void) { return \"1.2.3\"; }
")

c contract lib:
    fn lib_version
        returns static CStr

fn main:
    let v = lib_version()
    print(v.unwrap().to_str_lossy())
