//! expect-stdout: ok

// Tests: f-string formatting — integer display, bool display, string display,
//        multi-hole, expressions, concat with f-strings

// === Integer formatting ===

fn test_int_decimal:
    let x = 42
    assert(f"{x}" == "42")
    let y = -7
    assert(f"{y}" == "-7")
    let z = 0
    assert(f"{z}" == "0")

fn test_int_i64:
    let x: i64 = 1000000i64
    assert(f"{x}" == "1000000")
    let y: i64 = -999i64
    assert(f"{y}" == "-999")

fn test_int_in_text:
    let n = 100
    assert(f"count: {n}" == "count: 100")
    assert(f"{n} items" == "100 items")

// === Bool formatting ===

fn test_bool_display:
    let t = true
    let f = false
    assert(f"{t}" == "true")
    assert(f"{f}" == "false")
    assert(f"flag={t}" == "flag=true")

// === String formatting ===

fn test_str_passthrough:
    let s = "hello"
    assert(f"{s}" == "hello")
    assert(f"say {s}!" == "say hello!")

fn test_str_empty:
    let s = ""
    assert(f"{s}" == "")
    assert(f"a{s}b" == "ab")

// === Multi-hole f-strings ===

fn test_multi_hole:
    let a = 1
    let b = 2
    assert(f"{a}+{b}={a+b}" == "1+2=3")

fn test_adjacent_holes:
    let x = 10
    let y = 20
    assert(f"{x}{y}" == "1020")

fn test_three_holes:
    let a = "x"
    let b = "y"
    let c = "z"
    assert(f"{a}-{b}-{c}" == "x-y-z")

// === Expressions in holes ===

fn test_arithmetic_expr:
    assert(f"{2 + 3}" == "5")
    assert(f"{10 * 10}" == "100")
    assert(f"{7 - 3}" == "4")

fn test_comparison_result:
    let x = 5
    let r = x > 3
    assert(f"{r}" == "true")

fn test_array_index:
    let arr = [10, 20, 30]
    assert(f"{arr[0]}" == "10")
    assert(f"mid={arr[1]}" == "mid=20")

// === F-strings with other operations ===

fn test_fstring_concat:
    let name = "world"
    let s = f"hello {name}" ++ "!"
    assert(s == "hello world!")

fn test_fstring_in_loop:
    var result = ""
    var i = 1
    while i <= 3:
        result = result ++ f"{i} "
        i = i + 1
    assert(result == "1 2 3 ")

fn test_fstring_in_condition:
    let x = 42
    let s = if x > 0: f"positive: {x}" else: f"non-positive: {x}"
    assert(s == "positive: 42")

fn test_empty_fstring:
    assert(f"" == "")

fn test_literal_only:
    assert(f"hello" == "hello")

fn main:
    test_int_decimal()
    test_int_i64()
    test_int_in_text()
    test_bool_display()
    test_str_passthrough()
    test_str_empty()
    test_multi_hole()
    test_adjacent_holes()
    test_three_holes()
    test_arithmetic_expr()
    test_comparison_result()
    test_array_index()
    test_fstring_concat()
    test_fstring_in_loop()
    test_fstring_in_condition()
    test_empty_fstring()
    test_literal_only()
    println("ok")
