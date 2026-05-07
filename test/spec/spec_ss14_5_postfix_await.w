//! skip: non-executable spec sketch for Section 14.5 — Postfix `.await` (formerly 25.33); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.5 — Postfix `.await` (formerly 25.33)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic postfix .await
async fn fetch(url: str) -> Result[String, IoError]: ...
async fn test:
    let data = fetch("http://example.com").await
    assert(data.is_ok())

// PASS: chaining .await with ?
async fn test:
    let text = fetch("http://example.com").await?
    assert(text.len() > 0)

// PASS: chaining .await through method calls
async fn test(pool: &Pool):
    let row = pool.acquire().await?.query("SELECT 1").await?
    assert(row.is_some())

// PASS: .await on stored task
async fn test:
    let task = fetch("http://example.com")   // Task, not awaited yet
    let result = task.await                   // await later
    assert(result.is_ok())
