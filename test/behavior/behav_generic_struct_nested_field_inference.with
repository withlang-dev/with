//! expect-stdout: ok

type FivePointers[A, B, C, D, E] {
    a: *mut A,
    b: *mut B,
    c: *mut C,
    d: *mut D,
    e: *mut E,
}

fn main:
    var a: i8 = 1
    var b: i16 = 2
    var c: i32 = 3
    var d: i64 = 4
    var e: u8 = 5
    let values = FivePointers {
        a: &raw mut a,
        b: &raw mut b,
        c: &raw mut c,
        d: &raw mut d,
        e: &raw mut e,
    }
    unsafe:
        assert(*values.a == 1)
        assert(*values.b == 2)
        assert(*values.c == 3)
        assert(*values.d == 4)
        assert(*values.e == 5)
    print("ok")
