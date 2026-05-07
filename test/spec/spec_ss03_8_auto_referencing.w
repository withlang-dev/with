//! skip: non-executable spec sketch for Section 3.8 — Auto-Referencing (formerly 25.91); contains pseudo-code for unimplemented feature work
// Spec test: Section 3.8 — Auto-Referencing (formerly 25.91)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: auto-ref for shared borrow parameter
fn len(s: &str) -> usize: s.len()
fn test:
    let name: str = "Alice"
    assert(len(name) == 5)               // compiler inserts &name

// PASS: auto-ref for method receiver
fn test:
    type Point { x: f64, y: f64 }
    impl Point
        fn magnitude(self: &Self) -> f64: (self.x * self.x + self.y * self.y).sqrt()
    let p = Point { x: 3.0, y: 4.0 }
    assert(p.magnitude() == 5.0)          // auto-ref: p → &p

// FAIL: no auto-ref for &mut
fn mutate(s: &mut str): s.push_str("!")
fn test_fail:
    var name: str = "Alice"
    mutate(name)                          // ERROR: won't auto-ref to &mut
    mutate(&mut name)                     // OK: explicit &mut
