//! skip
// Spec test: Section 9.7 — Parameter Patterns (formerly 25.25)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: struct destructuring in parameters
fn distance({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point) -> f64:
    let dx = x2 - x1
    let dy = y2 - y1
    (dx * dx + dy * dy).sqrt()

fn test:
    let d = distance(Point { x: 0.0, y: 0.0 }, Point { x: 3.0, y: 4.0 })
    assert(d == 5.0)

// PASS: tuple destructuring in parameters
fn swap((a, b): (i32, i32)) -> (i32, i32): (b, a)

fn test:
    assert(swap((1, 2)) == (2, 1))

// PASS: destructuring in for loop
fn test:
    let pairs = vec![(1, "a"), (2, "b")]
    for (num, letter) in pairs:
        print(f"{num}: {letter}")
