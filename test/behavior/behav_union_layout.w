//! expect-stdout: ok

type PtrBox { p: *const u8 = null }
type IntBox { n: i32 = 0 }
type Overlap = union { ptr: PtrBox, int: IntBox }
type Wide = union { word: i64, bytes: [16]u8 }

fn check_second_field() -> i32 {
    var u = Overlap { int: IntBox { n: 42 } }
    u.int.n
}

fn check_wide_layout() -> i32 {
    var u = Wide { bytes: [1 as u8; 16] }
    u.bytes[15] as i32
}

fn main() {
    assert(sizeof[Wide]() == 16)
    assert(alignof[Wide]() == 8)
    assert(check_second_field() == 42)
    assert(check_wide_layout() == 1)
    print("ok")
}
