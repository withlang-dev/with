//! skip
// Spec test: Section 14.6 — Async Blocks (formerly 25.59)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: async: block returns Task[T]
async fn test:
    let task = async:
        sleep(10.millis()).await
        42
    let result = task.await
    assert(result == 42)

// PASS: async: block in structured concurrency
async fn test:
    async scope s =>
        s.track(async:
            print("hello from fiber 1")
        )
        s.track(async:
            print("hello from fiber 2")
        )

// PASS: async: block captures variables
async fn test:
    let url = "http://example.com"
    let task = async:
        fetch(url).await    // captures url by reference
    let result = task.await
