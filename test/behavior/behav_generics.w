//! expect-stdout: ok

// Tests: generic functions, generic structs, generic methods,
//        multiple type params, generic with constraints

fn swap[T](a: T, b: T) -> (T, T):
    (b, a)

fn test_swap_generic:
    let (a, b) = swap(1, 2)
    assert(a == 2)
    assert(b == 1)
    let (c, d) = swap("hello", "world")
    assert(c == "world")
    assert(d == "hello")

fn max_of[T](a: T, b: T) -> T:
    if a > b: a else: b

fn min_of[T](a: T, b: T) -> T:
    if a < b: a else: b

fn test_generic_comparison:
    assert(max_of(3, 7) == 7)
    assert(min_of(3, 7) == 3)
    assert(max_of(100, 50) == 100)

type Box[T] { value: T }

fn Box.get(self: Box[T]) -> T:
    self.value

fn test_generic_struct:
    let b: Box[i32] = Box { value: 42 }
    assert(b.get() == 42)
    let s: Box[str] = Box { value: "hello" }
    assert(s.get() == "hello")

type Pair[T] { first: T, second: T }

fn Pair.sum(self: Pair[i32]) -> i32:
    self.first + self.second

fn test_generic_pair:
    let p: Pair[i32] = Pair { first: 10, second: 20 }
    assert(p.sum() == 30)
    assert(p.first == 10)
    assert(p.second == 20)

fn apply[T](f: fn(T) -> T, x: T) -> T:
    f(x)

fn double(n: i32) -> i32:
    n * 2

fn negate(n: i32) -> i32:
    -n

fn test_generic_higher_order:
    assert(apply(double, 21) == 42)
    assert(apply(negate, 5) == -5)

fn test_generic_with_multiple_calls:
    // Same generic function called with different types
    let a = max_of(1, 2)
    let b = max_of(100, 50)
    assert(a == 2)
    assert(b == 100)

fn main:
    test_swap_generic()
    test_generic_comparison()
    test_generic_struct()
    test_generic_pair()
    test_generic_higher_order()
    test_generic_with_multiple_calls()
    print("ok")
