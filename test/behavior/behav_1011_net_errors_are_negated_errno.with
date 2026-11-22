//! expect-stdout: ok
//! skip-on: windows #800: std.net has no Windows backend
// #1011: std.net reports a failure as -errno (EBADF is -9 on macOS and
// Linux), as its documentation now says; send's said "-1 on error", and a
// caller checking `== -1` missed every real error.
use std.net

fn main:
    let fd = tcp_listen(0)
    assert(fd >= 0)
    assert(socket_close(fd) == 0)
    assert(send(fd, "x") == -9)
    assert(socket_close(fd) == -9)
    print("ok")
