//! expect-stdout: ok

// Behavior test: basic semantic analysis
// Tests: scoping, function calls, type checking, variable binding

fn add(a: i32, b: i32) -> i32:
    a + b

fn greet(name: str) -> str:
    name

fn test_basic_types:
    let x = 10
    let y = 20
    let sum = x + y
    assert(sum == 30)

fn test_function_calls:
    let result = add(3, 7)
    assert(result == 10)
    let name = greet("hello")
    assert(name == "hello")

fn test_nested_scope:
    let x = 10
    var result = 0
    if true:
        let y = 20
        result = x + y
    assert(result == 30)

fn test_bool_and_comparison:
    let a = 5
    let b = 10
    assert(a < b)
    assert(b > a)
    assert(a != b)
    assert(a == 5)

fn main:
    test_basic_types()
    test_function_calls()
    test_nested_scope()
    test_bool_and_comparison()
    print(int_to_string(10))
    print("ok")
