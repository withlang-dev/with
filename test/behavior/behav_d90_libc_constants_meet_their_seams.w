//! expect-stdout: ok

// D90 point 1 (#2070): a std.libc constant is the value its function
// accepts. zlib's gz_open passed Darwin's O_EXCL (0x800), which the `open`
// seam read as its own O_APPEND, so "wx" opened an existing file; and
// O_APPEND itself (Darwin's 8) was a bit the seam ignored.

use std.libc
use std.fs
use std.process

fn main:
    let path_text = f"out/with-d90-flags-{pid()}.txt"
    let owned = path_text.to_cstring().unwrap()
    let path = owned.as_cstr().ptr()
    libc.unlink(path)
    // Exclusive create: the first succeeds, the second is refused.
    let first = libc.open(path, libc.O_WRONLY | libc.O_CREAT | libc.O_EXCL, 420)
    assert(first >= 0, "exclusive create of a new file")
    assert(libc.write(first, c"abc".ptr as *const c_void, 3) == 3)
    assert(libc.close(first) == 0)
    assert(libc.open(path, libc.O_WRONLY | libc.O_CREAT | libc.O_EXCL, 420) < 0, "O_EXCL on an existing file")

    // Append: every write lands at the end, and F_GETFL says so in
    // std.libc's numbering.
    let appender = libc.open(path, libc.O_WRONLY | libc.O_APPEND, 0)
    assert(appender >= 0)
    let status = libc.fcntl(appender, libc.F_GETFL)
    assert((status & libc.O_APPEND) != 0, "F_GETFL reports O_APPEND")
    assert((status & 3) == libc.O_WRONLY)
    assert(libc.lseek(appender, 0, libc.SEEK_SET) == 0)
    assert(libc.write(appender, c"de".ptr as *const c_void, 2) == 2)

    // F_SETFL takes the same numbering back.
    assert(libc.fcntl(appender, libc.F_SETFL, status | libc.O_NONBLOCK) >= 0)
    assert((libc.fcntl(appender, libc.F_GETFL) & libc.O_NONBLOCK) != 0, "O_NONBLOCK set through F_SETFL")
    assert(libc.close(appender) == 0)
    assert(read_file(path_text).unwrap() == "abcde")
    libc.unlink(path)
    print("ok")
