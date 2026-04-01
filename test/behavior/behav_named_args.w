//! expect-stdout: ok

fn add(a: i32, b: i32) -> i32:
    a + b

fn greet(name: str, greeting: str) -> str:
    f"{greeting}, {name}!"

fn with_default(x: i32, y: i32 = 10) -> i32:
    x + y

fn three_params(a: i32, b: i32, c: i32) -> i32:
    a * 100 + b * 10 + c

fn test_named_args:
    // Named args in order
    assert(add(a: 3, b: 4) == 7)
    // Named args out of order
    assert(add(b: 4, a: 3) == 7)

fn test_mixed_args:
    // Positional then named
    assert(add(3, b: 4) == 7)
    // All positional still works
    assert(add(3, 4) == 7)

fn test_named_with_defaults:
    // Named with default skipped
    assert(with_default(x: 5) == 15)
    // Named overriding default
    assert(with_default(x: 5, y: 20) == 25)
    // Just positional with default
    assert(with_default(5) == 15)

fn test_reorder:
    // Named args reorder to match parameter order
    assert(three_params(c: 3, a: 1, b: 2) == 123)
    assert(three_params(1, c: 3, b: 2) == 123)

fn main:
    test_named_args()
    test_mixed_args()
    test_named_with_defaults()
    test_reorder()
    print("ok")
