//! expect-stdout: ok

// Test: std.builtins names are available through the ambient prelude.

fn main:
    assert(true)
    require(true, "require should pass")
    check(true, "check should pass")

    assert(int_to_string(0) == "0")
    assert(int_to_string(-42) == "-42")

    let i: i32 = -7
    let j: i64 = 1234567890123i64
    let u: u32 = 42u32
    let v: u64 = 99u64
    let vmax: u64 = 18446744073709551615u64

    assert(i.to_string() == "-7")
    assert(j.to_string() == "1234567890123")
    assert(u.to_string() == "42")
    assert(v.to_string() == "99")
    assert(vmax.to_string() == "18446744073709551615")
    assert(true.to_string() == "true")
    assert(false.to_string() == "false")

    print_i32(7)
    print_i64(8i64)
    print_bool(true)
    print("ok")
