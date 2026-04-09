// test/behavior/behav_zero_init.w

fn test_int:
    var x: i32
    assert(x == 0)

fn test_float:
    var f: f64
    assert(f == 0.0)

fn test_bool:
    var b: bool
    assert(b == false)

fn test_pointer:
    var p: *mut i32
    assert(p == null)

fn test_array:
    var buf: [100]u8
    var i = 0
    while i < 100:
        assert(buf[i] == 0)
        i = i + 1

fn main:
    test_int()
    test_float()
    test_bool()
    test_pointer()
    test_array()
    print("ok")
