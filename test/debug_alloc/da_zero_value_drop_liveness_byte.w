//! expect-debug-alloc: leak count=0
//! expect-stdout: took 0
//! expect-stdout: close 0
//! expect-stdout: took 5
//! expect-stdout: close 5
//! expect-stdout: end
//! expect-stdout: close 0
//! expect-stdout: close 7
//! expect-stdout: vec closed 2
//! expect-stdout: payload close 0
//! expect-stdout: close 0
//! expect-stdout: moved close 0
//! expect-stdout: close 0
//! expect-stdout: total 4
//! expect-stdout: ok

// §2.5.1 / D72 (#1431): a `Drop` value whose bytes are all zero is a live
// value, not the reset sentinel. `Fd { n: 0 }` gets a hidden liveness byte:
// its destructor runs once from a List, from an enum payload, and after a
// move (the moved-out source is blanked, so it does not run twice).

var closes = 0

type Fd { n: i32 }
impl Drop for Fd:
    move fn drop():
        closes += 1
        print(f"close {self.n}")

enum Carrier:
    A
    B(i32, Fd)

fn take(f: Fd):
    print(f"took {f.n}")

fn payload():
    let e = Carrier.B(14, Fd { n: 0 })
    match e:
        .B(k, _) => print(if k == 14: "payload close 0" else: "bad")
        .A => print("bad")

fn moved():
    let f = Fd { n: 0 }
    let g = f
    print("moved close 0")

fn list_case():
    var v: List[Fd] = List.new()
    v.push(Fd { n: 0 })
    v.push(Fd { n: 7 })
    print("end")

fn main:
    take(Fd { n: 0 })
    take(Fd { n: 5 })
    closes = 0
    list_case()
    let list_closed = closes
    print(f"vec closed {list_closed}")
    closes = 0
    payload()
    let payload_closed = closes
    closes = 0
    moved()
    let moved_closed = closes
    print(f"total {list_closed + payload_closed + moved_closed}")
    print("ok")
