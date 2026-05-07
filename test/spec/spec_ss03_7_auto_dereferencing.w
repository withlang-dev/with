//! skip: non-executable spec sketch for Section 3.7 — Auto-Dereferencing (formerly 25.90); contains pseudo-code for unimplemented feature work
// Spec test: Section 3.7 — Auto-Dereferencing (formerly 25.90)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: auto-deref through Box
fn test:
    type User { name: str }
    let u: Box[User] = Box.new(User { name: "Alice" })
    assert(u.name == "Alice")             // auto-deref Box → User → .name

// PASS: auto-deref through multiple references
fn test:
    let x = 42
    let r = &x
    let rr = &r
    assert(rr == 42)                      // auto-deref through &&i32

// PASS: auto-deref for method calls
fn test:
    let v: Box[Vec[i32]] = Box.new(vec![1, 2, 3])
    assert(v.len() == 3)                  // auto-deref Box → Vec → .len()
