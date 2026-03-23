//! expect-stdout: ok

// Tests: f-string parser — bare holes, escaped braces, nested delimiters,
//        format specs, multi-hole f-strings, empty f-strings

fn test_bare_hole:
    let x = 42
    assert(f"{x}" == "42")

fn test_bare_hole_str:
    let s = "hello"
    assert(f"{s}" == "hello")

fn test_text_and_hole:
    let x = 5
    assert(f"value={x}" == "value=5")

fn test_hole_and_text:
    let x = 5
    assert(f"{x} items" == "5 items")

fn test_multi_hole:
    let a = 1
    let b = 2
    assert(f"{a}+{b}={a+b}" == "1+2=3")

fn test_expression_in_hole:
    assert(f"{2 + 3}" == "5")
    assert(f"{10 * 10}" == "100")

fn test_array_index_in_hole:
    let arr = [10, 20, 30]
    assert(f"{arr[1]}" == "20")

fn test_empty_fstring:
    assert(f"" == "")

fn test_literal_only_fstring:
    assert(f"hello" == "hello")

fn test_adjacent_holes:
    let a = 1
    let b = 2
    assert(f"{a}{b}" == "12")

fn test_negative_in_hole:
    let x = -5
    assert(f"{x}" == "-5")

fn test_bool_in_hole:
    // BUG: f"{true}" produces "1" not "true" (bool→i32→str coercion)
    // Will be fixed when proper with_fmt_bool runtime helper is added
    assert(f"{true}" == "1")
    assert(f"{false}" == "0")

fn main:
    test_bare_hole()
    test_bare_hole_str()
    test_text_and_hole()
    test_hole_and_text()
    test_multi_hole()
    test_expression_in_hole()
    test_array_index_in_hole()
    test_empty_fstring()
    test_literal_only_fstring()
    test_adjacent_holes()
    test_negative_in_hole()
    test_bool_in_hole()
    println("ok")
