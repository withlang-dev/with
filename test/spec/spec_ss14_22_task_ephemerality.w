//! skip: non-executable spec sketch for Section 14.22 — Task Ephemerality (formerly 25.32); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.22 — Task Ephemerality (formerly 25.32)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: owned-argument task is storable
async fn fetch(id: i32) -> String: ...
fn test:
    let task = fetch(42)                // Task[String], storable
    let tasks: Vec[Task[String]] = vec![task]  // OK: can store

// FAIL: borrowing task is ephemeral, cannot store
async fn process(data: &mut Vec[i32]) -> Unit: ...
fn test:
    var v = vec![1, 2, 3]
    let task = process(&mut v)
    let stored: Vec[Task[Unit]] = vec![task]  // ERROR: ephemeral Task

// PASS: borrowing task in async scope
async fn test:
    var v = vec![1, 2, 3]
    async scope s =>
        let t = s.track(process(&mut v))
        t.await                            // OK: completes before scope exit
