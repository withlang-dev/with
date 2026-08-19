//! expect-stdout: ok
//! skip-windows-aarch64: #876 loopback TCP/UDP exchange exits 134 only on the windows-11-arm CI runner (byte-identical net runtime to the green x64 lane)

// #658: the server-side std.net surface must actually work. TCP: listen
// on port 0, discover the ephemeral port, connect, accept, exchange
// bytes both ways. UDP: bind port 0, connect a sender to it, deliver a
// datagram. Loopback only; every fd closed.

use std.net

fn main:
    let lfd = tcp_listen(0)
    assert(lfd >= 0)
    let port = sock_port(lfd)
    assert(port > 0)
    let cfd = tcp_connect("127.0.0.1", port)
    assert(cfd >= 0)
    let afd = tcp_accept(lfd)
    assert(afd >= 0)
    assert(send(cfd, "ping") == 4)
    assert(recv(afd, 16) == "ping")
    assert(send(afd, "pong") == 4)
    assert(recv(cfd, 16) == "pong")
    assert(socket_close(cfd) == 0)
    assert(socket_close(afd) == 0)
    assert(socket_close(lfd) == 0)

    let ufd = udp_bind(0)
    assert(ufd >= 0)
    let uport = sock_port(ufd)
    assert(uport > 0)
    let sfd = udp_connect("127.0.0.1", uport)
    assert(sfd >= 0)
    assert(send(sfd, "dgram") == 5)
    assert(recv(ufd, 16) == "dgram")
    assert(socket_close(sfd) == 0)
    assert(socket_close(ufd) == 0)
    print("ok")
