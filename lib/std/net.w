// std.net — Networking primitives
//
// Provides TCP and UDP socket operations wrapping POSIX APIs.

extern fn with_net_tcp_listen(port: i32, backlog: i32) -> i32
extern fn with_net_tcp_accept(listen_fd: i32) -> i32
extern fn with_net_tcp_connect(host: str, port: i32) -> i32
extern fn with_net_send(fd: i32, data: str) -> i64
extern fn with_net_recv(fd: i32, max_len: i64) -> str
extern fn with_net_close(fd: i32) -> i32
extern fn with_net_udp_bind(port: i32) -> i32

/// Create a TCP listener on the given port. Returns fd >= 0 on success, -1 on failure.
pub fn tcp_listen(port: i32) -> i32:
    with_net_tcp_listen(port, 128)

/// Accept a connection on a listening socket. Returns client fd >= 0, or -1.
pub fn tcp_accept(listen_fd: i32) -> i32:
    with_net_tcp_accept(listen_fd)

/// Connect to a remote host via TCP. Returns fd >= 0 on success, -1 on failure.
pub fn tcp_connect(host: str, port: i32) -> i32:
    with_net_tcp_connect(host, port)

/// Send data over a socket. Returns bytes sent, or -1 on error.
pub fn send(fd: i32, data: str) -> i64:
    with_net_send(fd, data)

/// Receive up to `max_len` bytes from a socket. Returns "" on error or EOF.
pub fn recv(fd: i32, max_len: i64) -> str:
    with_net_recv(fd, max_len)

/// Close a socket. Returns 0 on success.
pub fn socket_close(fd: i32) -> i32:
    with_net_close(fd)

/// Create a UDP socket bound to the given port. Returns fd >= 0, or -1.
pub fn udp_bind(port: i32) -> i32:
    with_net_udp_bind(port)
