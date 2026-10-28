//! expect-stdout: ok
//! skip-on: windows #800: std.tls rides std.net, which has no Windows backend
// #1061: the stub TLS peer. openssl s_server (present on every darwin/linux
// host this suite runs on; its absence fails this test loudly) serves the
// tls1061/ family over TLS 1.2 while std.http connects with SSL_CERT_FILE
// naming the trust bundle — the seam is the real one a user has. The good
// chains are accepted; a wrong-SAN leaf, an untrusted chain, a one-byte
// tamper of the ServerKeyExchange signature (via the TCP proxy below) and
// a one-byte tamper of the encrypted Finished are all refused. Every one
// of these refusals connected before TLS authenticated anything.
use std.http
use std.net
use std.process
use std.string
use std.sync
use std.time

fn cert(name: str) -> str:
    "test/behavior/tls1061/" ++ name

// Run one s_server for the whole case; stopped by pkill on its unique port.
// LibreSSL's -accept takes a bare port (it binds the wildcard address; the
// client still connects over loopback only).
fn serve(port: i32, cert_file: str, key_file: str) -> i32:
    run(&["openssl", "s_server", "-accept", f"{port}", "-cert", cert_file, "-key", key_file, "-www", "-tls1_2", "-quiet"])

fn stop_server(port: i32):
    let _ = run(&["pkill", "-f", f"s_server -accept {port}"])

// Wait until the server accepts TCP (the probe connection is dropped).
// The budget is wall time, not tries: a refused loopback connect returns
// instantly, so a try count can expire before the server has even exec'd
// (observed on Linux: 30 tries in under a millisecond).
fn wait_ready(port: i32) -> bool:
    let deadline = now_ns() + 5000000000
    while now_ns() < deadline:
        let fd = tcp_connect_timeout("127.0.0.1", port, 100)
        if fd >= 0:
            let _ = socket_close(fd)
            return true
    false

fn fetch(port: i32) -> i32:
    https_get_response_timeout(f"https://127.0.0.1:{port}/", 0, 3000, 3000).status

// One direct case: serve, fetch once, stop. Returns the HTTP status
// (-1 when TLS refused or the connection failed).
fn direct_case(port: i32, cert_file: str, key_file: str, roots: str) -> i32:
    set_env("SSL_CERT_FILE", roots)
    var status = -99
    scope s =>:
        let server = s.spawn(() => serve(port, cert_file, key_file))
        if wait_ready(port):
            status = fetch(port)
        stop_server(port)
        let _ = server.join()
    status

// ── Tampering proxy ────────────────────────────────────────────────
// mode 1 flips the last byte of the ServerKeyExchange signature;
// mode 2 flips the first payload byte of the first record after the
// server's ChangeCipherSpec (its encrypted Finished).

fn flipped(bytes: str, at: isize) -> str:
    var b = StringBuilder.new()
    for i in 0..bytes.len():
        if i == at: b.push_byte((bytes[i] ^ 1) as u8) else: b.push_byte(bytes[i] as u8)
    b.to_str()

type Tamper  {
    mode: i32,
    buf: str,
    hs: str,
    hs_off: isize,
    done: bool,
    after_ccs: bool,
}

impl Tamper:
    // Feed server→client bytes; returns the bytes to forward now.
    mut fn feed(chunk: str) -> str:
        self.buf = self.buf ++ chunk
        var out = StringBuilder.new()
        while self.buf.len() >= 5:
            let rlen = (self.buf[3] as isize) * 256 + (self.buf[4] as isize)
            if self.buf.len() < 5 + rlen:
                break
            var record = self.buf.slice(0, 5 + rlen)
            let rtype = self.buf[0] as i32
            self.buf = self.buf.slice(5 + rlen, self.buf.len())
            if self.mode == 2 and self.after_ccs and not self.done and rlen > 0:
                record = flipped(record, 5)
                self.done = true
            if rtype == 20:
                self.after_ccs = true
            if self.mode == 1 and rtype == 22 and not self.done:
                let hs_before = self.hs.len()
                self.hs = self.hs ++ record.slice(5, record.len())
                while self.hs_off + 4 <= self.hs.len():
                    let mlen = (self.hs[self.hs_off + 1] as isize) * 65536 + (self.hs[self.hs_off + 2] as isize) * 256 + (self.hs[self.hs_off + 3] as isize)
                    if self.hs_off + 4 + mlen > self.hs.len():
                        break
                    if (self.hs[self.hs_off] as i32) == 12:
                        let rel = self.hs_off + 4 + mlen - 1 - hs_before
                        if rel >= 0 and rel < rlen:
                            record = flipped(record, 5 + rel)
                            self.done = true
                    self.hs_off = self.hs_off + 4 + mlen
            for i in 0..record.len():
                out.push_byte(record[i] as u8)
        out.to_str()

fn pump_plain(src: i32, dst: i32) -> isize:
    var total: isize = 0
    var go = true
    while go:
        let chunk = recv(src, 16384)
        if chunk.len() == 0:
            go = false
        else:
            total = total + chunk.len()
            let _ = send(dst, chunk)
    let _ = socket_close(dst)
    total

fn pump_tamper(src: i32, dst: i32, mode: i32) -> isize:
    var t = Tamper { mode, buf: "", hs: "", hs_off: 0, done: false, after_ccs: false }
    var total: isize = 0
    var go = true
    while go:
        let chunk = recv(src, 16384)
        if chunk.len() == 0:
            go = false
        else:
            let fwd = t.feed(chunk)
            total = total + fwd.len()
            if fwd.len() > 0:
                let _ = send(dst, fwd)
    let _ = socket_close(dst)
    total

fn proxy_once(lfd: i32, server_port: i32, mode: i32) -> isize:
    let cfd = tcp_accept(lfd)
    if cfd < 0: return -1
    let sfd = tcp_connect_timeout("127.0.0.1", server_port, 2000)
    if sfd < 0:
        let _ = socket_close(cfd)
        return -1
    let _ = set_timeout(cfd, 5000)
    let _ = set_timeout(sfd, 5000)
    var moved: isize = 0
    scope sc =>:
        let up = sc.spawn(() => pump_plain(cfd, sfd))
        moved = pump_tamper(sfd, cfd, mode)
        let _ = up.join()
    let _ = socket_close(cfd)
    moved

fn proxy_case(server_port: i32, proxy_port: i32, cert_file: str, key_file: str, roots: str, mode: i32) -> i32:
    set_env("SSL_CERT_FILE", roots)
    var status = -99
    scope s =>:
        let server = s.spawn(() => serve(server_port, cert_file, key_file))
        let lfd = tcp_listen(proxy_port)
        if lfd >= 0 and wait_ready(server_port):
            let proxy = s.spawn(() => proxy_once(lfd, server_port, mode))
            status = fetch(proxy_port)
            // Free a proxy still parked in accept (a client that never came).
            let poke = tcp_connect_timeout("127.0.0.1", proxy_port, 500)
            let _ = proxy.join()
            if poke >= 0: let _ = socket_close(poke)
            let _ = socket_close(lfd)
        stop_server(server_port)
        let _ = server.join()
    status

fn main:
    let base = 20000 + pid() % 15000
    let root = cert("root.pem")
    // Good chains: RSA, EC and P-384 leaves. (LibreSSL s_server sends one
    // certificate, so these leaves sit directly under their roots; the
    // three-certificate chain is behav_1061_x509_chain_verify's ground.)
    assert(direct_case(base, cert("leaf_rsadirect.pem"), cert("leaf_rsadirect_key.pem"), root) == 200)
    assert(direct_case(base + 1, cert("leaf_ec.pem"), cert("leaf_ec_key.pem"), root) == 200)
    assert(direct_case(base + 2, cert("leaf384.pem"), cert("leaf384_key.pem"), cert("ca384.pem")) == 200)
    // Wrong SAN and untrusted chain refuse.
    assert(direct_case(base + 3, cert("wrong.pem"), cert("wrong_key.pem"), root) == -1)
    assert(direct_case(base + 4, cert("leaf_ec.pem"), cert("leaf_ec_key.pem"), cert("selfsigned.pem")) == -1)
    // The proxy alone changes nothing; its tampers refuse.
    assert(proxy_case(base + 5, base + 105, cert("leaf_rsadirect.pem"), cert("leaf_rsadirect_key.pem"), root, 0) == 200)
    assert(proxy_case(base + 6, base + 106, cert("leaf_rsadirect.pem"), cert("leaf_rsadirect_key.pem"), root, 1) == -1)
    assert(proxy_case(base + 7, base + 107, cert("leaf_rsadirect.pem"), cert("leaf_rsadirect_key.pem"), root, 2) == -1)
    print("ok")
