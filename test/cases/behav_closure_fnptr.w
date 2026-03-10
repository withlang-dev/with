//! expect-stdout: ok

// Behavior test: closures as function pointers / higher-order functions
// Tests: fn pointers, passing functions, returning from higher-order fns

fn add_one(x: i32) -> i32:
    x + 1

fn triple(x: i32) -> i32:
    x * 3

fn negate(x: i32) -> i32:
    0 - x

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn test_named_fn_as_ptr:
    assert(apply(add_one, 10) == 11)
    assert(apply(triple, 10) == 30)
    assert(apply(negate, 10) == -10)

fn test_closure_as_fn_ptr:
    assert(apply(|x| x * 2, 5) == 10)
    assert(apply(|x| x + 100, 0) == 100)

fn apply_twice(f: fn(i32) -> i32, x: i32) -> i32:
    f(f(x))

fn test_apply_twice:
    assert(apply_twice(add_one, 0) == 2)
    assert(apply_twice(triple, 2) == 18)
    assert(apply_twice(|x| x + 10, 0) == 20)

fn apply_predicate(f: fn(i32) -> bool, x: i32) -> bool:
    f(x)

fn is_even(x: i32) -> bool:
    x % 2 == 0

fn test_predicate_fn_ptr:
    assert(apply_predicate(is_even, 4) == true)
    assert(apply_predicate(is_even, 3) == false)
    assert(apply_predicate(|x| x > 0, 5) == true)
    assert(apply_predicate(|x| x > 0, -1) == false)

fn main:
    test_named_fn_as_ptr()
    test_closure_as_fn_ptr()
    test_apply_twice()
    test_predicate_fn_ptr()
    println("ok")
