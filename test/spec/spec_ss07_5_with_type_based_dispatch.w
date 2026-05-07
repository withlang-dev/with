//! skip: non-executable spec sketch for Section 7.5 — With Type-Based Dispatch (formerly 25.69); contains pseudo-code for unimplemented feature work
// Spec test: Section 7.5 — With Type-Based Dispatch (formerly 25.69)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: Scoped type → automatic guarded access
fn test:
    let lock = Mutex.new(vec![1, 2, 3])
    with lock.lock() as data:          // Mutex implements Scoped → guard
        assert(data.len() == 3)

// PASS: non-Scoped type → simple builder binding
fn test:
    let config = with Config.default() as mut c:
        c.retries = 3                  // Config is not Scoped → builder
    assert(config.retries == 3)
