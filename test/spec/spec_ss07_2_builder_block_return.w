//! skip: non-executable spec sketch for Section 7.2 — Builder Block Return (formerly 25.50); contains pseudo-code for unimplemented feature work
// Spec test: Section 7.2 — Builder Block Return (formerly 25.50)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: last statement is assignment (Unit) → returns builder
fn test:
    let c = with Config { timeout: 0, retries: 0 } as mut c:
        c.timeout = 30
        c.retries = 3
    assert(c.timeout == 30)
    assert(c.retries == 3)

// PASS: push returns Unit → returns builder
fn test:
    let v = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
        v.push(3)
    assert(v.len() == 3)

// PASS: last statement is Unit (assignment) → builder returned
// even though insert() returns Option[i32]
fn test:
    let m = with HashMap.new() as mut m:
        m.insert("a", 1)    // returns Option[i32]
        m.insert("b", 2)    // returns Option[i32]... but:
        m.len()              // this is non-Unit — block returns 2!
    // m is now i32, not HashMap
    assert(m == 2)

// PASS: extract value from builder
fn test:
    let len = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
        v.len()              // non-Unit → block returns 2
    assert(len == 2)

// PASS: works as function return value
fn make_config -> Config:
    with Config.default() as mut c:
        c.timeout = 30
