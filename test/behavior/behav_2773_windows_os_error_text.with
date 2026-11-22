//! only-on: windows
//! expect-stdout: ok

// #2773: on Windows an IoError carries a Win32 error code, and its message
// is the system's text for it (FormatMessageW). The C library's strerror
// read the code as an errno: ERROR_INVALID_NAME (123) printed "no protocol
// option". A name with `<` is ERROR_INVALID_NAME.
use std.fs

fn main:
    match read_file("C:/with-2773-<bad>.txt"):
        Ok(_) => print("read")
        Err(e) =>
            let text = e.message()
            assert(not text.contains("protocol"))
            assert(text.ends_with("(os error 123)"))
            print("ok")
