//! skip: non-executable spec sketch for Section 9.7 — Reference Pattern Ergonomics (formerly 25.60); contains pseudo-code for unimplemented feature work
// Spec test: Section 9.7 — Reference Pattern Ergonomics (formerly 25.60)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: for loop destructuring auto-borrows
fn test:
    let items = vec![("alice", 1), ("bob", 2)]
    for (name, val) in items:        // yields &(str, i32)
        assert(name.len() > 0)       // name: &str
        assert(*val > 0)              // val: &i32

// PASS: match on borrowed Option
fn describe(opt: &Option[String]) -> &str:
    match opt:
        Some(s) => s.as_str()         // s: &String
        None    => "none"

fn test:
    let x = Some("hello".to_string())
    assert(describe(&x) == "hello")

// PASS: nested tuple destructuring through reference
fn test:
    let pairs: Vec[(i32, i32)] = vec![(1, 2), (3, 4)]
    for (a, b) in pairs:
        assert(*a + *b > 0)           // a: &i32, b: &i32
