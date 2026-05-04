//! skip
// Spec test: Section 9.2 — Tail Recursion (formerly 25.12)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: valid
@[tailrec]
fn factorial(n: Int, acc: Int) -> Int:
    match n { 0 => acc, _ => factorial(n - 1, n * acc) }

// FAIL: not in tail position
@[tailrec]
fn bad(n: Int) -> Int:
    match n { 0 => 1, _ => n * bad(n - 1) }  // ERROR

// FAIL: defer prevents tail-call guarantee
@[tailrec]
fn also_bad(n: Int) -> Int:
    if n <= 0: 0
    defer: log(n)
    also_bad(n - 1)                         // ERROR
