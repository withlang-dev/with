//! expect-stdout: ok

fn take_int(x: Int) -> i64:
    x

fn take_uint(x: UInt) -> u64:
    x

fn test_annotations_and_casts:
    let signed: Int = -1
    let unsigned: UInt = 1u64
    assert(signed == -1i64)
    assert(unsigned == 1u64)
    assert(take_int(41 as Int) == 41i64)
    assert(take_uint(42 as UInt) == 42u64)

fn test_width_and_methods:
    let signed: Int = 0x12345678 as Int
    let unsigned: UInt = 0x12345678 as UInt
    assert(signed.rotate_left(4) == 0x123456780 as Int)
    assert(unsigned.swap_bytes() == 0x7856341200000000 as UInt)
    assert(unsigned.popcount() == 13)
    assert((0 as Int).clz() == 64)
    assert((0 as UInt).ctz() == 64)

fn test_generic_arguments:
    let xs: Vec[Int] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    let counts: HashMap[str, UInt] = HashMap.new()
    counts.insert("answer", 42 as UInt)
    assert(xs.get(2) == 3)
    assert(counts.get("answer").unwrap() == 42u64)

fn main:
    test_annotations_and_casts()
    test_width_and_methods()
    test_generic_arguments()
    print("ok")
