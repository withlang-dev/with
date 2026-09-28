//! expect-stdout: u32 64 ok
//! expect-stdout: u32 65 ok
//! expect-stdout: u32 100 ok
//! expect-stdout: u32 1000 ok
//! expect-stdout: u16 80 ok
//! expect-stdout: u64 72 ok
//! expect-stdout: i32 100 ok
//! expect-stdout: const 100 ok
//! expect-stdout: pair 100 ok
//! expect-stdout: bool 100 ok

// #1049: a repeat `[v; N]` with N > 64 and a multi-byte element set only the
// first N / sizeof(T) elements; the rest was stack garbage (`[7; 100]` read
// back `7 37486657`). The fill stored all N; the copy into the binding
// carried the element count as its byte length (#1050).

type Pair:
    a: i32
    b: i64

const COUNT = 100

fn check(name: str, n: i32, bad: i32):
    if bad == 0: print(f"{name} {n} ok") else: print(f"{name} {n} bad={bad}")

fn main:
    let a64 = [5 as u32; 64]
    var bad = 0
    for i in 0..64:
        if a64[i] != 5 as u32: bad = bad + 1
    check("u32", 64, bad)
    let a65 = [5 as u32; 65]
    bad = 0
    for i in 0..65:
        if a65[i] != 5 as u32: bad = bad + 1
    check("u32", 65, bad)
    var a100: [100]u32 = [5 as u32; 100]
    bad = 0
    for i in 0..100:
        if a100[i] != 5 as u32: bad = bad + 1
    check("u32", 100, bad)
    let a1000 = [5 as u32; 1000]
    bad = 0
    for i in 0..1000:
        if a1000[i] != 5 as u32: bad = bad + 1
    check("u32", 1000, bad)
    let h = [9 as u16; 80]
    bad = 0
    for i in 0..80:
        if h[i] != 9 as u16: bad = bad + 1
    check("u16", 80, bad)
    let w = [3 as u64; 72]
    bad = 0
    for i in 0..72:
        if w[i] != 3 as u64: bad = bad + 1
    check("u64", 72, bad)
    let s = [7; 100]
    bad = 0
    for i in 0..100:
        if s[i] != 7: bad = bad + 1
    check("i32", 100, bad)
    let k = [7; COUNT]
    bad = 0
    for i in 0..COUNT:
        if k[i] != 7: bad = bad + 1
    check("const", COUNT, bad)
    let p = [Pair { a: 1, b: 2 }; 100]
    bad = 0
    for i in 0..100:
        if p[i].a != 1 or p[i].b != 2: bad = bad + 1
    check("pair", 100, bad)
    let t = [true; 100]
    bad = 0
    for i in 0..100:
        if not t[i]: bad = bad + 1
    check("bool", 100, bad)
