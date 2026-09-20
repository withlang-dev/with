//! expect-stdout: ok

// §16.1: `CStr.from_ptr(p).to_str()` reads the C string C handed back. The
// view is `unsafe` to make (the caller vouches the pointer is a live
// NUL-terminated string); the `str` is an owned copy that outlives it.
use c_import("char *getenv(const char *name);\nchar *strerror(int code);\n")

fn main:
    let message = unsafe { CStr.from_ptr(strerror(2)) }.to_str()
    assert(message.len() > 0 and not message.contains("\0"))

    let view = unsafe { CStr.from_ptr(c"with".ptr) }
    assert(view.len() == 4 and view.to_str() == "with")
    assert(unsafe { CStr.from_ptr(c"".ptr) }.to_str() == "")

    // Null is information: a nullable return is an Option before it is a view.
    let missing = getenv("WITH_NO_SUCH_VARIABLE_").as_option().map(p => unsafe { CStr.from_ptr(p) }.to_str())
    assert(missing == None)
    print("ok")
