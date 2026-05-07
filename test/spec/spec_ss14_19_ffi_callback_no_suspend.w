//! skip: non-executable spec sketch for Section 14.19 — FFI Callback No-Suspend (formerly 25.68); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.19 — FFI Callback No-Suspend (formerly 25.68)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: may_suspend in extern "C" callback
fn test_fail:
    unsafe { c_sort(items.ptr, items.len, (a, b) =>
        fetch_weight(a).await <=> fetch_weight(b).await
        //              ^^^^^^ ERROR: may_suspend in C callback
    ) }

// PASS: no suspension in callback
fn test:
    unsafe { c_sort(items.ptr, items.len, (a, b) =>
        a.weight <=> b.weight        // OK: no suspension
    ) }
