//! expect-stdout: ok
//! skip-on: windows #800: std.tls rides std.net, which has no Windows backend
// #2648: an https URL's explicit port is the port connected to. The parser
// kept 443 and made the host `127.0.0.1:<port>`, so the connect failed and
// this listener never heard a ClientHello.
use std.http
use std.net
use std.sync

// The bytes the first connection sends: a ClientHello from the client, or
// nothing from the poke that frees an accept the client never reached.
fn first_bytes(lfd: i32) -> isize:
    let afd = tcp_accept(lfd)
    if afd < 0: return -1
    let _ = set_timeout(afd, 2000)
    let n = recv(afd, 4096).len()
    let _ = socket_close(afd)
    n

fn main:
    let lfd = tcp_listen(0)
    assert(lfd >= 0)
    let port = sock_port(lfd)
    var heard: isize = -1
    var status = 0
    scope s =>:
        let server = s.spawn(() => first_bytes(lfd))
        status = https_get_response_timeout(f"https://127.0.0.1:{port}/", 0, 2000, 2000).status
        let poke = tcp_connect_timeout("127.0.0.1", port, 2000)
        heard = server.join()
        if poke >= 0: let _ = socket_close(poke)
    assert(socket_close(lfd) == 0)
    // The client reached this port and spoke; the peer closed without a
    // handshake, so there is no response.
    assert(heard > 0)
    assert(status == -1)
    print("ok")
