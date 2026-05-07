//! skip: non-executable spec sketch for Section 20b.6 — Comptime Unreachable Exemption (formerly 25.66); contains pseudo-code for unimplemented feature work
// Spec test: Section 20b.6 — Comptime Unreachable Exemption (formerly 25.66)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: code after comptime if return is not flagged unreachable
fn compute(x: i32) -> i32:
    comptime if cfg.is_debug:
        return 0
    // In release: reachable. In debug: erased by comptime.
    x * x + 1

// FAIL: code after unconditional return is still unreachable
fn test_fail -> i32:
    return 0
    1 + 1                            // ERROR: unreachable code
