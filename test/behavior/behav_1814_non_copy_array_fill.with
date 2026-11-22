//! expect-stdout: 64 abc abc
//! expect-stdout: 65 abc abc
//! expect-stdout: 100 abc abc
//! expect-stdout: 1000 abc abc
//! expect-stdout: const 70 abc
//! expect-stdout: made 65 dropped 65
//! expect-stdout: made 3 dropped 3
//! expect-stdout: distinct 65
//! expect-stdout: end

// #1814 (§4.3a, §2.3): `[v; N]` with a non-Copy v evaluates v once per
// element at every N — the written form — so each element owns its own
// value. Over 64 elements the lowering took the one-evaluation fill: one
// `s.clone()` placed in N slots was N owners of one buffer (SIGSEGV at 65,
// a double free under the debug allocator). Run it with `--debug-alloc`:
// leak count 0, no double free.

global var MADE: i32 = 0
global var DROPPED: i32 = 0

type Tok:
    id: i32
impl Drop for Tok:
    move fn drop(): DROPPED = DROPPED + 1

fn tok() -> Tok:
    MADE = MADE + 1
    Tok { id: MADE }

const WIDE = 70

fn show(n: i32, first: &str, last: &str): print(f"{n} {first} {last}")

fn fills(s: &str):
    let a64: [str; 64] = [s; 64]
    show(64, a64[0], a64[63])
    let a65: [str; 65] = [s; 65]
    show(65, a65[0], a65[64])
    let a100: [str; 100] = [s; 100]
    show(100, a100[0], a100[99])
    let a1000: [str; 1000] = [s; 1000]
    show(1000, a1000[0], a1000[999])
    let w: [str; WIDE] = [s; WIDE]
    print(f"const {WIDE} {w[WIDE - 1]}")

fn toks():
    let t = [tok(); 65]
    var distinct = 0
    for i in 0..65:
        if t[i].id == i + 1: distinct = distinct + 1
    MADE = 0
    DROPPED = 0
    {
        let u = [tok(); 65]
        assert(u[64].id == 65)
    }
    print(f"made {MADE} dropped {DROPPED}")
    MADE = 0
    DROPPED = 0
    {
        let v = [tok(); 3]
        assert(v[2].id == 3)
    }
    print(f"made {MADE} dropped {DROPPED}")
    print(f"distinct {distinct}")

fn main:
    let s = "ab" ++ "c"
    fills(s)
    toks()
    print("end")
