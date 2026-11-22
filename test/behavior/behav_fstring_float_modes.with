//! expect-stdout: ok

fn test_fixed_mode:
    let x = 3.14159
    assert(f"{x:.2f}" == "3.14")
    assert(f"{3.0:f}" == "3.000000")

fn test_scientific_mode:
    let x = 3.14159
    assert(f"{x:.2e}" == "3.14e+00")
    assert(f"{3.0:e}" == "3.000000e+00")
    assert(f"{0.0314:.2e}" == "3.14e-02")

fn test_general_mode:
    let x = 3.14
    assert(f"{x:g}" == "3.14")

fn test_width_and_sign:
    let x = 3.14
    assert(f"{x:+10.2f}" == "     +3.14")
    assert(f"{x:010.2f}" == "0000003.14")

fn test_special_values_with_modes:
    let z = 0.0
    assert(f"{1.0 / z:f}" == "inf")
    assert(f"{-1.0 / z:e}" == "-inf")
    assert(f"{z / z:g}" == "nan")

fn main:
    test_fixed_mode()
    test_scientific_mode()
    test_general_mode()
    test_width_and_sign()
    test_special_values_with_modes()
    print("ok")
