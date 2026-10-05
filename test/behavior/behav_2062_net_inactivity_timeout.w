//! expect-stdout: ok
//! skip-on: windows-aarch64 #876 loopback TCP/UDP exchange exits 134 only on the windows-11-arm CI runner (byte-identical net runtime to the green x64 lane)

// #2062: a socket has an inactivity timeout. A peer that accepts and then
// says nothing ends a recv after the timeout instead of holding it forever
// (codeberg.org, 2026-10-03: thirty minutes inside one download). A timeout
// of 0 is "wait" again, and data that arrives in time is delivered. Loopback
// only; every fd closed.

use std.net
use std.time

fn main:
    let lfd = tcp_listen(0)
    assert(lfd >= 0)
    let port = sock_port(lfd)
    let cfd = tcp_connect_timeout("127.0.0.1", port, 2000)
    assert(cfd >= 0)
    let afd = tcp_accept(lfd)
    assert(afd >= 0)

    // The silent peer: recv gives up after about 300 ms.
    assert(set_timeout(cfd, 300) == 0)
    let start = now_ns()
    assert(recv(cfd, 16) == "")
    let waited_ms = (now_ns() - start) / 1000000
    assert(waited_ms >= 200)
    assert(waited_ms < 5000)

    // The socket still works, and bytes that are there are read at once.
    assert(send(afd, "late") == 4)
    assert(recv(cfd, 16) == "late")

    // A negative timeout is refused; 0 clears it.
    assert(set_timeout(cfd, -1) < 0)
    assert(set_timeout(cfd, 0) == 0)
    assert(send(afd, "x") == 1)
    assert(recv(cfd, 16) == "x")

    // Nothing listens on port 1: the connect fails, it does not hang.
    assert(tcp_connect_timeout("127.0.0.1", 1, 2000) < 0)

    assert(socket_close(cfd) == 0)
    assert(socket_close(afd) == 0)
    assert(socket_close(lfd) == 0)
    print("ok")
