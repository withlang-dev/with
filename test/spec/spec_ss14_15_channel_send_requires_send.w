//! skip
// Spec test: Section 14.15 — Channel Send Requires Send (formerly 25.76)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: ephemeral values cannot be sent over channels
fn test_fail:
    async scope s =>
        let (tx, rx) = chan[&str](10)
        s.track(async:
            let local = "hello".to_owned()
            tx.send(local.as_view()).await  // ERROR: &str is not Send
        )

// PASS: owned values over channels
fn test:
    let (tx, rx) = chan[String](10)
    tx.send("hello").await                  // str literal, String is Send
