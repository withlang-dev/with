//! skip: non-executable spec sketch for Section 14.9 — Select Await (formerly 25.51); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.9 — Select Await (formerly 25.51)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic select with timeout
async fn test:
    let (tx, rx) = channel[str]()
    tx.send("hello").await
    select await
        msg = rx.recv() => assert(msg == "hello")
        _ = timeout(1.secs()) => unreachable()

// PASS: select in a loop with break
async fn test:
    let (tx, rx) = channel[i32]()
    var sum = 0
    tx.send(1).await
    tx.send(2).await
    tx.close()
    loop:
        select await
            n = rx.recv() => sum += n
            _ = timeout(100.millis()) => break
    assert(sum == 3)

// PASS: select with error propagation
async fn do_work(rx: Receiver[str], cancel: CancelToken) -> Result[str, AppError]:
    select await
        msg = rx.recv() => Ok(msg)
        _ = cancel.cancelled() => Err(.Cancelled)
