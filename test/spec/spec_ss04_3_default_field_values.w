//! skip
// Spec test: Section 4.3 — Default Field Values (formerly 25.42)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

type Config {
    host: str = "localhost",
    port: u16 = 8080,
    debug: bool = false,
}

// PASS: omit fields with defaults
fn test:
    let c = Config { port: 9090 }
    assert(c.host == "localhost")
    assert(c.port == 9090)
    assert(c.debug == false)

// PASS: all defaults
fn test_all_defaults:
    let c = Config {}
    assert(c.port == 8080)

// PASS: override all fields
fn test_all_explicit:
    let c = Config { host: "0.0.0.0", port: 443, debug: true }
    assert(c.debug == true)

// PASS: defaults with field shorthand
fn test_shorthand:
    let host = "example.com"
    let c = Config { host, debug: true }
    assert(c.host == "example.com")
    assert(c.port == 8080)

// PASS: fresh evaluation per construction
type Counter { id: usize = next_id() }
fn test_fresh:
    let a = Counter {}
    let b = Counter {}
    assert(a.id != b.id)

// FAIL: omit field without default
type Required {
    name: str,              // no default
    age: i32 = 0,
}
fn test_fail:
    let r = Required { age: 25 }   // ERROR: missing field `name`
