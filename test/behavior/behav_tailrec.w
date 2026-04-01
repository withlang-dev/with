//! expect-stdout: ok

@[tailrec]
fn sum_to(n: i32, acc: i32) -> i32:
    if n <= 0: acc
    else: sum_to(n - 1, acc + n)

@[tailrec]
fn factorial_acc(n: i32, acc: i32) -> i32:
    if n <= 1: acc
    else: factorial_acc(n - 1, n * acc)

fn main:
    assert(sum_to(10, 0) == 55)
    assert(sum_to(100, 0) == 5050)
    assert(factorial_acc(5, 1) == 120)
    assert(factorial_acc(10, 1) == 3628800)
    print("ok")
