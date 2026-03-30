//! expect-stdout: ok

// Tests: format spec wiring — hex, width, padding, precision

fn test_int_hex:
    assert(f"{255:x}" == "ff")

fn test_int_hex_upper:
    assert(f"{255:X}" == "FF")

fn test_int_binary:
    assert(f"{7:b}" == "111")

fn test_int_octal:
    assert(f"{63:o}" == "77")

fn test_int_width:
    assert(f"{42:8}" == "      42")

fn test_int_zero_pad:
    assert(f"{42:08}" == "00000042")

fn test_int_sign:
    assert(f"{42:+}" == "+42")

fn test_int_alt_hex:
    assert(f"{255:#x}" == "0xff")

fn main:
    test_int_hex()
    test_int_hex_upper()
    test_int_binary()
    test_int_octal()
    test_int_width()
    test_int_zero_pad()
    test_int_sign()
    test_int_alt_hex()
    print("ok")
