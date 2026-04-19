//! expect-stdout: ok

fn test_basic_separator:
    let x = 1; let y = 2; let z = 3
    assert(x + y + z == 6)

fn test_in_braces {
    let a = 10; let b = 20; let r = a + b
    assert(r == 30)
}

fn test_trailing_semicolon:
    let x = 42;
    assert(x == 42)

fn test_consecutive_semicolons:
    let x = 1;; let y = 2;;; let z = 3
    assert(x + y + z == 6)

fn test_mixed_newlines_semicolons:
    let a = 1;
    let b = 2
    let c = 3; let d = 4
    assert(a + b + c + d == 10)

fn test_return_before_semicolon:
    let r = helper_return()
    assert(r == 42)

fn helper_return() -> i32:
    return 42; return 99

fn test_if_with_semicolons:
    let x = 5
    if x > 0:
        let a = 1; let b = 2
        assert(a + b == 3)

fn test_while_with_semicolons:
    var i = 0; var sum = 0
    while i < 5:
        sum = sum + i; i = i + 1
    assert(sum == 10)

fn test_for_with_semicolons:
    var sum = 0
    for i in 0..5:
        let x = i * 2; sum = sum + x
    assert(sum == 20)

fn test_match_inline_braces:
    var x = 0; var y = 0; var z = 0
    let v = 1
    match v:
        0 => x = 99
        1 =>
            x = 1; y = 2; z = 3
        _ => z = 99
    assert(x == 1)
    assert(y == 2)
    assert(z == 3)

fn main:
    test_basic_separator()
    test_in_braces()
    test_trailing_semicolon()
    test_consecutive_semicolons()
    test_mixed_newlines_semicolons()
    test_return_before_semicolon()
    test_if_with_semicolons()
    test_while_with_semicolons()
    test_for_with_semicolons()
    test_match_inline_braces()
    print("ok")
