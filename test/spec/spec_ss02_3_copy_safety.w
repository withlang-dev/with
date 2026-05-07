//! skip: non-executable spec sketch for Section 2.3 — Copy Safety (formerly 25.31); contains pseudo-code for unimplemented feature work
// Spec test: Section 2.3 — Copy Safety (formerly 25.31)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: Copy on all-Copy struct
type Point { x: f64, y: f64 }
impl Copy for Point

// FAIL: Copy on struct with non-Copy field
type Buffer { data: Vec[u8] }
impl Copy for Buffer              // ERROR: field `data` is not Copy

// FAIL: Copy + Drop on same type
type Handle { fd: i32 }
impl Drop for Handle:
    fn drop(self): close(self.fd)
impl Copy for Handle              // ERROR: Copy + Drop is forbidden

// PASS: Copy on struct with only primitives
type Color { r: u8, g: u8, b: u8, a: u8 }
impl Copy for Color               // OK: all fields are Copy
