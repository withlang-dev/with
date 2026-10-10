//! expect-stdout: u32 64 ok
//! expect-stdout: u32 65 ok
//! expect-stdout: u32 100 ok
//! expect-stdout: u32 1000 ok
//! expect-stdout: u16 100 ok
//! expect-stdout: u64 100 ok
//! expect-stdout: u8 100 ok
//! expect-stdout: pair 100 ok

// #1050: a value copy of `[T; N]` with N > 64 emitted `llvm.memcpy` with the
// element COUNT as its byte length, so only N / sizeof(T) elements were
// copied and the tail was stack garbage. The sources are written element by
// element, so a wrong element is the copy's.

type Pair:
    a: i32
    b: i64

fn check(name: str, n: i32, bad: i32):
    if bad == 0: print(f"{name} {n} ok") else: print(f"{name} {n} bad={bad}")

fn main:
    var b64: [64]u32 = [0 as u32; 64]
    for i in 0..64: b64[i] = i as u32
    let c64 = b64
    var bad: i32 = 0
    for i in 0..64:
        if c64[i] != i as u32: bad = bad + 1
    check("u32", 64, bad)

    var b65: [65]u32 = [0 as u32; 65]
    for i in 0..65: b65[i] = i as u32
    let c65 = b65
    bad = 0
    for i in 0..65:
        if c65[i] != i as u32: bad = bad + 1
    check("u32", 65, bad)

    var b100: [100]u32 = [0 as u32; 100]
    for i in 0..100: b100[i] = i as u32
    let c100 = b100
    bad = 0
    for i in 0..100:
        if c100[i] != i as u32: bad = bad + 1
    check("u32", 100, bad)

    var b1000: [1000]u32 = [0 as u32; 1000]
    for i in 0..1000: b1000[i] = i as u32
    let c1000 = b1000
    bad = 0
    for i in 0..1000:
        if c1000[i] != i as u32: bad = bad + 1
    check("u32", 1000, bad)

    var h: [100]u16 = [0 as u16; 100]
    for i in 0..100: h[i] = i as u16
    let hc = h
    bad = 0
    for i in 0..100:
        if hc[i] != i as u16: bad = bad + 1
    check("u16", 100, bad)

    var w: [100]u64 = [0 as u64; 100]
    for i in 0..100: w[i] = i as u64
    let wc = w
    bad = 0
    for i in 0..100:
        if wc[i] != i as u64: bad = bad + 1
    check("u64", 100, bad)

    var y: [100]u8 = [0 as u8; 100]
    for i in 0..100: y[i] = i as u8
    let yc = y
    bad = 0
    for i in 0..100:
        if yc[i] != i as u8: bad = bad + 1
    check("u8", 100, bad)

    var p: [100]Pair = [Pair { a: 0, b: 0 }; 100]
    for i in 0i32..100: p[i] = Pair { a: i, b: i * 2 }
    let pc = p
    bad = 0
    for i in 0..100:
        if pc[i].a != i or pc[i].b != i * 2: bad = bad + 1
    check("pair", 100, bad)
