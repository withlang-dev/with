//! expect-stdout: ok

// Tests: ++ is str-only concatenation. F-strings handle formatting.
// Verifies that str ++ str works, and f-strings properly format
// non-str values before concatenation.

fn test_str_concat_basic:
    let a = "hello"
    let b = " world"
    assert(a ++ b == "hello world")

fn test_str_concat_with_fstring:
    let n = 42
    let s = f"{n}" ++ " items"
    assert(s == "42 items")

fn test_str_concat_fstring_both:
    let x = 10
    let y = 20
    assert(f"{x}" ++ "+" ++ f"{y}" == "10+20")

fn test_fstring_int_formatting:
    let x: i32 = 42
    assert(f"val={x}" == "val=42")

fn test_fstring_i64_formatting:
    let x: i64 = 100i64
    assert(f"val={x}" == "val=100")

fn test_fstring_bool_formatting:
    assert(f"{true}" == "true")
    assert(f"{false}" == "false")

fn test_fstring_str_passthrough:
    let s = "hello"
    assert(f"{s}" == "hello")

fn test_fstring_expr_formatting:
    assert(f"{2 + 3}" == "5")
    assert(f"result={10 * 2}" == "result=20")

fn test_fstring_multi_type_holes:
    let n = 42
    let flag = true
    let name = "test"
    assert(f"{name}: {n} ({flag})" == "test: 42 (true)")

fn test_concat_chain:
    let parts = "a" ++ "b" ++ "c" ++ "d"
    assert(parts == "abcd")

fn main:
    test_str_concat_basic()
    test_str_concat_with_fstring()
    test_str_concat_fstring_both()
    test_fstring_int_formatting()
    test_fstring_i64_formatting()
    test_fstring_bool_formatting()
    test_fstring_str_passthrough()
    test_fstring_expr_formatting()
    test_fstring_multi_type_holes()
    test_concat_chain()
    println("ok")
