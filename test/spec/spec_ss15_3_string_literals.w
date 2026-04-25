//! skip
// Spec test: Section 15.3 — String Literals (formerly 25.44)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: string literal is str by default (owned)
fn test:
    let s = "hello"                          // s: str — no annotation needed
    assert(s.len() == 5)

// PASS: explicit &str annotation gives static reference
fn test:
    let view: &str = "hello"                 // &str — zero-cost static ref
    assert(view.len() == 5)

// PASS: str in struct fields — no annotation on the literal
fn test:
    type Config { host: str, port: i32 }
    let c = Config { host: "localhost", port: 8080 }
    assert(c.host == "localhost")

// PASS: str in function args
fn register(name: str): assert(name.len() > 0)
fn test: register("Alice")

// PASS: &str parameter context — auto-borrows, no allocation
fn greet(name: &str): assert(name.len() > 0)
fn test: greet("Alice")

// PASS: return type str — literal just works
fn get_name -> str: "Alice"
fn test: assert(get_name() == "Alice")
