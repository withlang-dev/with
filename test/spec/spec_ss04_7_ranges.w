//! skip: non-executable spec sketch for Section 4.7 — Ranges (formerly 25.23); contains pseudo-code for unimplemented feature work
// Spec test: Section 4.7 — Ranges (formerly 25.23)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: range in for loop
fn test:
    var sum = 0
    for i in 0..5: sum += i
    assert(sum == 10)

// PASS: inclusive range
fn test:
    var sum = 0
    for i in 0..=5: sum += i
    assert(sum == 15)

// PASS: range as iterator
fn test:
    let squares = (0..5) |> map(x => x * x) |> collect[Vec]()
    assert(squares == vec![0, 1, 4, 9, 16])

// PASS: range in pattern
fn test(code: i32) -> str:
    match code:
        200..=299 => "ok"
        _ => "other"
