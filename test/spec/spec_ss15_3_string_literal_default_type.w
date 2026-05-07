//! skip: non-executable spec sketch for Section 15.3 — String Literal Default Type (formerly 25.87); contains pseudo-code for unimplemented feature work
// Spec test: Section 15.3 — String Literal Default Type (formerly 25.87)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: literal is str by default — no annotation
fn test:
    let s = "hello"
    assert(s.len() == 5)

// PASS: str in struct field — no annotation on literal
fn test:
    type Config { host: str, port: i32 }
    let c = Config { host: "localhost", port: 8080 }
    assert(c.host == "localhost")

// PASS: str in function parameter
fn greet(name: str): assert(name.len() > 0)
fn test: greet("Alice")

// PASS: str in return type
fn name -> str: "Alice"
fn test: assert(name() == "Alice")

// PASS: explicit &str annotation gives static reference
fn test:
    let view: &str = "hello"  // &str — zero-cost, no allocation
    assert(view.len() == 5)
