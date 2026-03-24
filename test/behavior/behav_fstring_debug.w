//! expect-stdout: ok

// Tests: :? debug mode for primitives

fn test_debug_int:
    let x = 42
    assert(f"{x:?}" == "42")

fn test_debug_negative_int:
    let x = 0 - 7
    assert(f"{x:?}" == "-7")

fn test_debug_bool_true:
    assert(f"{true:?}" == "true")

fn test_debug_bool_false:
    assert(f"{false:?}" == "false")

fn test_debug_str:
    let s = "hello"
    assert(f"{s:?}" == "\"hello\"")

fn test_debug_str_empty:
    let s = ""
    assert(f"{s:?}" == "\"\"")

fn test_debug_str_in_context:
    let name = "alice"
    assert(f"name={name:?}" == "name=\"alice\"")

fn test_debug_int_in_context:
    let x = 42
    assert(f"val={x:?}" == "val=42")

fn main:
    test_debug_int()
    test_debug_negative_int()
    test_debug_bool_true()
    test_debug_bool_false()
    test_debug_str()
    test_debug_str_empty()
    test_debug_str_in_context()
    test_debug_int_in_context()
    println("ok")
