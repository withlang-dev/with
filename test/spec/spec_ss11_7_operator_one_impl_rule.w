//! skip: non-executable spec sketch for Section 11.7 — Operator One-Impl Rule (formerly 25.71); contains pseudo-code for unimplemented feature work
// Spec test: Section 11.7 — Operator One-Impl Rule (formerly 25.71)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: unique Output per (Self, Rhs) pair
impl Add[Vector, Vector] for Vector:
    fn add(self: Vector, rhs: Vector) -> Vector: ...
impl Add[f32, Vector] for Vector:   // different Rhs = OK
    fn add(self: Vector, rhs: f32) -> Vector: ...
let v = vec1 + vec2   // Output uniquely determined: Vector

// FAIL: conflicting Output for same (Self, Rhs)
impl Add[Vector, Matrix] for Vector: ...   // ERROR: Vector + Vector
                                               // already has Output = Vector
