//! expect-stdout: write: 3
//! expect-stdout: read: 8 9
//! expect-stdout: vec: 2 9
//! expect-stdout: ok

// #604 stage 1 for methods (found by D64): a Vec or array argument coerces
// to a `[]T` / `[]mut T` parameter of a method exactly as it does for a free
// function — the `[]mut` view demands a mutable place, and the caller's
// binding is valid after the call (§4.8a).

type Sink { x: i32 }
impl Sink:
    fn write(src: []u8) -> i32: src.len() as i32
    fn read(dst: []mut u8) -> i32:
        dst[0] = 9
        dst.len() as i32

fn main:
    let s = Sink { x: 1 }
    let data: [u8; 3] = [1, 2, 3]
    print(f"write: {s.write(data)}")
    var out: [u8; 8] = [0 as u8; 8]
    let n = s.read(out)
    print(f"read: {n} {out[0]}")
    var v: Vec[u8] = Vec.new()
    v.push(1)
    v.push(2)
    let m = s.read(v)
    print(f"vec: {m} {v[0]}")
    print("ok")
