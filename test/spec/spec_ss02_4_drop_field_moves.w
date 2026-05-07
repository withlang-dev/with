//! skip: non-executable spec sketch for Section 2.4 — Drop Field Moves (formerly 25.80); contains pseudo-code for unimplemented feature work
// Spec test: Section 2.4 — Drop Field Moves (formerly 25.80)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: field moves allowed INSIDE drop
type FileWrapper { fd: File, name: String }
impl Drop for FileWrapper:
    fn drop(self: Self):
        close_file(self.fd)   // OK: field move inside drop
        // self.name NOT moved → compiler drops it automatically

// FAIL: field moves forbidden OUTSIDE drop
fn test_fail:
    let w = FileWrapper { fd: open_file(), name: "A" }
    let fd = w.fd             // ERROR: partial move from Drop type
