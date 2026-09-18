use std.net

fn main -> i32:
    // T15: ephemeral bind + sock_port discovery
    let fd = tcp_listen(0)
    print("listen0 fd=" ++ fd.to_string() ++ " ok=" ++ (fd >= 0).to_string())
    let p = sock_port(fd)
    print("sock_port=" ++ p.to_string() ++ " ephemeral=" ++ (p > 0).to_string())
    // T15: double-bind same port (SO_REUSEADDR set by runtime; expect EADDRINUSE=-98 on Linux)
    let fd2 = tcp_listen(p)
    print("rebind fd2=" ++ fd2.to_string())
    // T15: invalid ports
    print("listen_neg=" ++ tcp_listen(-1).to_string())
    print("listen_big=" ++ tcp_listen(70000).to_string())
    // T15: udp ephemeral bind
    let u = udp_bind(0)
    print("udp0 fd=" ++ u.to_string() ++ " ok=" ++ (u >= 0).to_string())
    print("udp_port=" ++ sock_port(u).to_string())
    // T10: sock_port on bad fd
    print("sockport_bad=" ++ sock_port(-1).to_string())
    // cleanup
    print("close1=" ++ socket_close(fd).to_string())
    if fd2 >= 0:
        print("close2=" ++ socket_close(fd2).to_string())
    print("close_udp=" ++ socket_close(u).to_string())
    print("p1-done")
    0
