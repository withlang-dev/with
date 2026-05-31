// Spec test: Section 9.2 — Tail Recursion
// Executable subset of the §9.2 sketch (negative @[tailrec] cases omitted).

@[tailrec]
fn factorial(n: i32, acc: i32) -> i32:
    match n:
        0 => acc
        _ => factorial(n - 1, n * acc)

@[tailrec]
fn sum_to(n: i32, acc: i32) -> i32:
    if n == 0: return acc
    sum_to(n - 1, acc + n)

fn test_tailrec_factorial:
    assert(factorial(5, 1) == 120)

fn test_tailrec_sum:
    assert(sum_to(100, 0) == 5050)
