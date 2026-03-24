//! expect-stdout: ok

// Tests: float formatting with precision specs (benchmark-style)

fn test_float_precision_2:
    let x = 3.14159
    assert(f"{x:.2}" == "3.14")

fn test_float_precision_3:
    let x = 3.14159
    assert(f"{x:.3}" == "3.142")

fn test_float_precision_0:
    let x = 3.14159
    assert(f"{x:.0}" == "3")

fn test_float_precision_6:
    let x = 3.14159
    assert(f"{x:.6}" == "3.141590")

fn test_float_sign:
    let x = 3.14
    assert(f"{x:+.2}" == "+3.14")

fn main:
    test_float_precision_2()
    test_float_precision_3()
    test_float_precision_0()
    test_float_precision_6()
    test_float_sign()
    println("ok")
