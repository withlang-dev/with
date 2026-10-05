//! expect-stdout: true 11 true 2

// A constant whose value holds a unit enum variant keeps the variant. The
// compile-time evaluator typed a variant as its representation integer, so
// a folded `Pair { os: .Linux, n: 2 }` came back as `Pair { os: 1, n: 2 }`:
// "type mismatch in struct literal field 'os': expected OsKind, got i32".

enum OsKind: i32:
    Macos
    Linux
    Windows

comptime fn the_os() -> OsKind: .Linux

type Pair { os: OsKind, n: i32 }

const K: OsKind = comptime the_os()
const P: Pair = Pair { os: .Linux, n: 2 }
const Q: Pair = comptime Pair { os: the_os(), n: 2 }

const EAGAIN: i32 = comptime match P.os:
    .Macos => 35
    .Linux => 11
    .Windows => 11

fn main:
    print(f"{K == .Linux} {EAGAIN} {P.os == Q.os} {Q.n}")
