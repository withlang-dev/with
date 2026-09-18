use std.net

fn main -> i32:
    // T23: refused connection on loopback (high port, nothing listening) -> -1, errno discarded
    let r = tcp_connect("127.0.0.1", 48123)
    print("refused=" ++ r.to_string())
    // T23: DNS failure -> -1 (same value as refused; indistinguishable)
    let d = tcp_connect("nonexistent.invalid", 80)
    print("dnsfail=" ++ d.to_string())
    print("same_code=" ++ (r == d).to_string())
    // T23: send/recv on invalid fd (avoids SIGPIPE; exercises error branch)
    print("send_bad=" ++ send(-1, "hello").to_string())
    let got = recv(-1, 64)
    print("recv_bad len=" ++ got.len().to_string() ++ " empty=" ++ (got == "").to_string())
    // T23: recv with max_len 0 -> "" by construction
    print("recv_zero len=" ++ recv(-1, 0).len().to_string())
    // T23: udp_connect does no handshake; fails only on DNS/port-format errors
    let u = udp_connect("127.0.0.1", 48124)
    print("udp_connect fd=" ++ u.to_string() ++ " ok=" ++ (u >= 0).to_string())
    if u >= 0:
        print("udp_close=" ++ socket_close(u).to_string())
    print("udp_dnsfail=" ++ udp_connect("nonexistent.invalid", 80).to_string())
    print("p2-done")
    0
