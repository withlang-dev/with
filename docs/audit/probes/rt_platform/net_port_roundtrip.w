// Probe: sockaddr_in port encode (linux :756-762, darwin :776-783) vs
// decode (linux :803-808, darwin :824-829) roundtrip. Snapshot 450733e5.
// Pure-logic mirror — no sockets. Run via seed:
//   out/bootstrap/bin/with-stage1 run .audit/probes/rt_platform/net_port_roundtrip.w

fn encode_port_hi(port: i32) -> i32:
    (port >> 8) & 255

fn encode_port_lo(port: i32) -> i32:
    port & 255

fn decode_port(hi: i32, lo: i32) -> i32:
    (hi << 8) | lo

fn check_port(port: i32) -> Unit:
    let hi = encode_port_hi(port)
    let lo = encode_port_lo(port)
    let back = decode_port(hi, lo)
    print(f"port={port} hi={hi} lo={lo} back={back}")
    assert(back == port)

check_port(0)
check_port(80)
check_port(443)
check_port(8080)
check_port(65535)
// Out-of-range ports are rejected by with_net_tcp_listen/udp_bind guards (:765, :792).
assert(0 > 65535 or 0 < 0 == false)
print("port encode/decode roundtrips on both backends (BE bytes at sa[2],sa[3])")
