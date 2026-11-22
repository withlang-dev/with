//! expect-stdout: ok
//! skip-on: windows #800: std.tls rides std.net, which has no Windows backend
// #1062: a TLS handshake message's 3-byte length comes from the server, and
// the client hashed and parsed that many bytes from a 16640-byte record
// buffer. A server that claims a 16 MiB ServerHello in a 4-byte record read
// far past the buffer. The client refuses the message instead.
use std.http
use std.net
use std.string
use std.sync

fn bytes(values: List[i32]) -> str:
    var b = StringBuilder.new()
    for v in values: b.push_byte(v as u8)
    b.to_str()

// Accepts one connection, reads the ClientHello, and answers with one
// handshake record (type 22, TLS 1.2, 4 bytes) holding a ServerHello header
// whose length is 0xFFFFFF. The bytes heard; 0 for the poke that frees an
// accept the client never reached.
fn serve_once(lfd: i32) -> isize:
    let afd = tcp_accept(lfd)
    if afd < 0: return -1
    let _ = set_timeout(afd, 2000)
    let heard = recv(afd, 4096).len()
    if heard > 0:
        let _sent = send(afd, bytes([22, 3, 3, 0, 4, 2, 255, 255, 255]))
        let _drain = recv(afd, 4096)
    let _ = socket_close(afd)
    heard

fn main:
    let lfd = tcp_listen(0)
    assert(lfd >= 0)
    let port = sock_port(lfd)
    var heard: isize = -1
    var status = 0
    scope s =>:
        let server = s.spawn(() => serve_once(lfd))
        status = https_get_response_timeout(f"https://127.0.0.1:{port}/", 0, 2000, 2000).status
        let poke = tcp_connect_timeout("127.0.0.1", port, 2000)
        heard = server.join()
        if poke >= 0: let _ = socket_close(poke)
    assert(socket_close(lfd) == 0)
    // The server's record arrived, and the handshake failed closed.
    assert(heard > 0)
    assert(status == -1)
    print("ok")
