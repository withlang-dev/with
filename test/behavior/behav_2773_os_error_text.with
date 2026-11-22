//! expect-stdout: ok

// #2773: an IoError's message is the platform's own text for its code,
// ending `(os error N)` (an errno on POSIX, a Win32 code on Windows).
use std.fs

fn main:
    match read_file("/with-2773-no-such-dir/missing.txt"):
        Ok(_) => print("read")
        Err(e) =>
            let text = e.message()
            assert(text.contains("(os error "))
            assert(not text.starts_with(" "))
            print("ok")
