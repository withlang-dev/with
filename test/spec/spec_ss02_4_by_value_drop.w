//! skip
// Spec test: Section 2.4 — By-Value Drop (formerly 25.61)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: drop takes self by value — no double-free risk
type Handle { fd: i32 }
impl Drop for Handle:
    fn drop(self: Self):
        close(self.fd)
        // self is consumed — no need to null out fd

// PASS: field destructors run after user drop body
type Wrapper { name: String, handle: Handle }
impl Drop for Wrapper:
    fn drop(self: Self):
        print(f"dropping {self.name}")
        // after this returns, Handle::drop runs for self.handle
        // then String::drop runs for self.name

// FAIL: Copy + Drop is still forbidden
type Bad { x: i32 } with Copy
impl Drop for Bad:
    fn drop(self: Self): ()  // ERROR: Copy + Drop conflict
