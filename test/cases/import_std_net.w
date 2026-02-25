// Test: std.net import
use std.net

fn main() -> i32 =
    // Test TCP listen on a random high port
    let fd = tcp_listen(0)
    assert(fd >= 0)
    socket_close(fd)
    0
