type Inner { x: i64 = 0 }
type S { inner: Inner, a: i64 = 0, b: i32 = 0 }
type PtrHolder { p: *const u8 = null }
type FnHolder { f: *const fn() -> i32 = null }

let bytes: [3]u8 = [7, 8, 9]

var s_global: S = S { inner: Inner { x: 9 }, a: 41, b: 7 }
var p_global: PtrHolder = PtrHolder { p: (&bytes[0] as *const u8) }
var f_global: FnHolder = FnHolder { f: answer }

fn answer() -> i32:
    41

fn main:
    assert(s_global.inner.x == 9)
    assert(s_global.a == 41)
    assert(s_global.b == 7)
    assert((unsafe: *p_global.p) == 7 as u8)
    assert(f_global.f() == 41)
    print("ok")
