//! skip
// Spec test: Section 13.3 — HashMap Convenience Methods (formerly 25.98)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: update with default and transform
fn test:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.update("alice", 0, n => n + 1)
    counts.update("alice", 0, n => n + 1)
    assert(counts.get("alice") == Some(&2))

// PASS: increment shorthand
fn test:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.increment("bob")
    counts.increment("bob")
    counts.increment("bob")
    assert(counts.get("bob") == Some(&3))
