//! expect-stdout: ok

// Behavior test: string interpolation with \{expr}

fn test_basic_interp:
    let name = "world"
    let s = "hello \{name}"
    assert(s == "hello world")

fn test_interp_int:
    let x = 42
    let s = "value is \{x}"
    assert(s == "value is 42")

fn test_interp_expr:
    let a = 3
    let b = 4
    let s = "sum is \{a + b}"
    assert(s == "sum is 7")

fn test_interp_multiple:
    let x = 1
    let y = 2
    let s = "\{x} and \{y}"
    assert(s == "1 and 2")

fn test_interp_empty_around:
    let v = "ok"
    let s = "\{v}"
    assert(s == "ok")

fn test_no_interp:
    let s = "plain string"
    assert(s == "plain string")

fn main:
    test_basic_interp()
    test_interp_int()
    test_interp_expr()
    test_interp_multiple()
    test_interp_empty_around()
    test_no_interp()
    println("ok")
