//! skip
// Spec test: Section 2.4 — Partial Move from Drop Types (formerly 25.64)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

type Wrapper { fd: File, name: String }
impl Drop for Wrapper:
    fn drop(self: Self): close(self.fd)

// FAIL: partial move from Drop type
fn test_fail:
    let w = Wrapper { fd: open(), name: "A" }
    let w2 = { w with name: "B" }  // ERROR: partial move from Drop type

// PASS: clone field instead
fn test:
    let w = Wrapper { fd: open(), name: "A" }
    let w2 = Wrapper { fd: w.fd.clone(), name: "B" }
