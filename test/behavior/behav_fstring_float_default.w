//! expect-stdout: ok

fn test_default_float_display:
    assert(f"{3.14}" == "3.14")
    assert(f"{10.0}" == "10")
    assert(f"{1.5}" == "1.5")
    assert(f"{0.5}" == "0.5")
    assert(f"{0.001}" == "0.001")

fn test_float_debug_matches_default:
    let x = 3.14
    assert(f"{x:?}" == f"{x}")

fn test_large_and_small_finite_values:
    let large = 1e308
    let small = 1e-308
    assert(f"{large}" == "1e+308")
    assert(f"{small}" == "1e-308")
    assert(f"{large}" != "inf")
    assert(f"{small}" != "0")

fn test_zero_and_special_values:
    let z = 0.0
    assert(f"{z}" == "0")
    assert(f"{-0.0}" == "-0")
    assert(f"{1.0 / z}" == "inf")
    assert(f"{-1.0 / z}" == "-inf")
    assert(f"{z / z}" == "nan")

fn main:
    test_default_float_display()
    test_float_debug_matches_default()
    test_large_and_small_finite_values()
    test_zero_and_special_values()
    print("ok")
