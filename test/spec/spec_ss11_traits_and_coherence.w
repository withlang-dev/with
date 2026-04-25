//! skip
// Spec test: Section 11 — Traits and Coherence (formerly 25.10)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

trait Show:
    fn show(self: &Self) -> String

// FAIL: orphan rule
impl Show for Vec[i32]:             // ERROR
    fn show(self: &Vec[i32]) -> String: "vec"

// PASS: own type
type MyType { x: i32 }
impl Show for MyType:
    fn show(self: &MyType) -> String: "MyType"
