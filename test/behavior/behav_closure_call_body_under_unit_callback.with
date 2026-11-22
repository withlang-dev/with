//! expect-stdout: 12 12 12

// A closure whose body is a call to a function returning a value, passed
// where `fn(..) -> Unit` is expected: the demand is the closure's result and
// the call's value is discarded (D43: the tail is a statement under
// `-> Unit`). The callee's return type was taken as the closure's instead,
// so a generic callback parameter refused `n => bump(n)` as returning i32
// (the list intrinsics hid it for `for_each`).
var total = 0i32

fn bump(n: i32) -> i32:
    total = total + n
    total

fn each(xs: &List[i32], f: fn(&i32) -> Unit):
    for x in xs: f(x)

fn each_of[T](xs: &List[T], f: fn(&T) -> Unit):
    for x in xs: f(x)

fn main:
    let xs: List[i32] = [3, 4, 5]
    each(xs, n => bump(n))
    let a = total
    total = 0
    each_of(xs, n => bump(n))
    let b = total
    total = 0
    xs.iter().for_each(n => bump(n))
    print(f"{a} {b} {total}")
