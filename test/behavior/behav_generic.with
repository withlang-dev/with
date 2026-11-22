//! expect-stdout: ok

// Behavior test: generics — generic functions, type parameters

fn identity[T](x: T) -> T:
    x

fn test_identity_i32:
    let r = identity(42)
    assert(r == 42)

fn test_identity_str:
    let r = identity("hello")
    assert(r == "hello")

fn test_identity_bool:
    let r = identity(true)
    assert(r == true)
    let r2 = identity(false)
    assert(r2 == false)

fn first_of_two[T](a: T, b: T) -> T:
    a

fn second_of_two[T](a: T, b: T) -> T:
    b

fn test_two_params:
    assert(first_of_two(1, 2) == 1)
    assert(second_of_two(1, 2) == 2)
    assert(first_of_two("a", "b") == "a")
    assert(second_of_two("a", "b") == "b")

fn apply_fn[T](f: fn(T) -> T, x: T) -> T:
    f(x)

fn double(n: i32) -> i32:
    n * 2

fn test_generic_with_fn_param:
    let r = apply_fn(double, 21)
    assert(r == 42)

fn main:
    test_identity_i32()
    test_identity_str()
    test_identity_bool()
    test_two_params()
    test_generic_with_fn_param()
    print("ok")
