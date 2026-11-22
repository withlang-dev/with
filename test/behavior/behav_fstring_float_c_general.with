//! expect-stdout: ok

// D68: default display follows C %g. Explicit e rounds to even.

fn divided_by_ten(start: f64, times: i32) -> f64:
    var x = start
    var i = 0
    while i < times:
        x = x / 10.0
        i = i + 1
    x

fn test_default_is_c_general:
    assert(f"{0.1 + 0.2}" == "0.3")
    assert(f"{1.0 / 3.0}" == "0.333333")
    assert(f"{2.0 / 3.0}" == "0.666667")
    assert(f"{0.1}" == "0.1")
    assert(f"{100.0}" == "100")
    assert(f"{123456.789}" == "123457")
    assert(f"{-2.5}" == "-2.5")

fn test_notation_uses_rounded_exponent:
    assert(f"{1.0 / 3.0 / 100000.0}" == "3.33333e-06")
    assert(f"{0.00009999999}" == "0.0001")
    assert(f"{999999.9}" == "1e+06")
    assert(f"{999999.0}" == "999999")
    assert(f"{0.00001}" == "1e-05")

fn test_scientific_digits_are_exact:
    assert(f"{1e-300}" == "1e-300")
    assert(f"{divided_by_ten(20.0 / 3.0, 79)}" == "6.66667e-79")
    assert(f"{1.7976931348623157e308}" == "1.79769e+308")
    assert(f"{5e-324}" == "4.94066e-324")
    assert(f"{1e15}" == "1e+15")

fn test_debug_and_g_match_default:
    let x = 0.1 + 0.2
    assert(f"{x:?}" == f"{x}")
    assert(f"{x:g}" == f"{x}")

fn test_e_mode_rounds_exactly:
    assert(f"{1e-300:e}" == "1.000000e-300")
    assert(f"{divided_by_ten(20.0 / 3.0, 79):.3e}" == "6.667e-79")
    assert(f"{0.125:.1e}" == "1.2e-01")
    assert(f"{9.9999:.2e}" == "1.00e+01")

fn test_explicit_general_precision:
    assert(f"{0.125:.2g}" == "0.12")
    assert(f"{0.375:.2g}" == "0.38")
    assert(f"{9.9999:.0g}" == "1e+01")
    assert(f"{1.0 / 3.0:.17g}" == "0.33333333333333331")
    assert(f"{0.1:.30g}" == "0.100000000000000005551115123126")
    assert(f"{0.1:.1100g}" == "0.1000000000000000055511151231257827021181583404541015625")

fn test_fixed_ties_and_large_integer:
    assert(f"{0.125:.2f}" == "0.12")
    assert(f"{0.375:.2f}" == "0.38")
    assert(f"{0.5:.0f}" == "0")
    assert(f"{1.5:.0f}" == "2")
    assert(f"{2.5:.0f}" == "2")
    assert(f"{1e30:.2f}" == "1000000000000000019884624838656.00")
    assert(f"{0.1:.30e}" == "1.000000000000000055511151231258e-01")
    assert(f"{3.14:+010.2f}" == "+000003.14")

fn main:
    test_default_is_c_general()
    test_notation_uses_rounded_exponent()
    test_scientific_digits_are_exact()
    test_debug_and_g_match_default()
    test_e_mode_rounds_exactly()
    test_explicit_general_precision()
    test_fixed_ties_and_large_integer()
    print("ok")
