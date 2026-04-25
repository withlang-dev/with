//! skip
// Spec test: Section 18.2 — Drop in Prelude (formerly 25.57)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: drop closes channel sender
fn test:
    let (tx, rx) = chan[i32](10)
    tx.send(1)
    tx.send(2)
    drop(tx)                     // close sender
    let items: Vec[i32] = rx.iter() |> collect()
    assert(items == vec![1, 2])
