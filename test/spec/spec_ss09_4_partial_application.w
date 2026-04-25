//! skip
// Spec test: Section 9.4 — Partial Application (formerly 25.13)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS
fn add(a: i32, b: i32) -> i32: a + b
fn test:
    let add5 = add(5, _)
    assert(add5(3) == 8)

// PASS: in pipeline
fn test:
    let result = vec![1, 2, 3] |> map(add(10, _)) |> collect[Vec]()
    assert(result == vec![11, 12, 13])

// PASS: multiple placeholders preserve left-to-right order
fn make_pair(a: str, b: i32, c: bool) -> str: "{a}:{b}:{c}"
fn test:
    let f = make_pair(_, 10, _)
    assert(f("x", true) == "x:10:true")

// FAIL: no implicit currying
fn test:
    let add5 = add(5)     // ERROR: wrong argument count
