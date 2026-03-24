//! expect-stdout: ok

// Tests: locale-independent formatting (decimal point stays '.')

extern fn int_to_string(n: i32) -> str

fn test_int_format_locale:
    // Integer formatting must produce consistent decimal output
    let s = f"{12345}"
    assert(s == "12345")

fn test_negative_int_locale:
    let s = f"{0 - 42}"
    assert(s == "-42")

fn test_bool_locale:
    assert(f"{true}" == "true")
    assert(f"{false}" == "false")

fn test_str_passthrough:
    // Strings should not be locale-affected
    let s = "hello"
    assert(f"{s}" == "hello")

fn main:
    test_int_format_locale()
    test_negative_int_locale()
    test_bool_locale()
    test_str_passthrough()
    println("ok")
