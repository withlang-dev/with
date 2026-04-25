//! skip
// Spec test: Section 14 — Async/Await (formerly 25.17)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic async function
async fn fetch_data(url: str) -> Result[String, IoError]:
    let resp = http.get(url).await
    resp.read_body().await

// PASS: await from any function
fn test:
    let data = fetch_data("http://example.com").await

// PASS: parallel tasks
fn test:
    let t1 = fetch_data("http://a.com")
    let t2 = fetch_data("http://b.com")
    let (a, b) = (t1.await, t2.await)

// PASS: references across await
async fn process(data: &mut Vec[i32]):
    let len = data.len()
    some_io().await
    data.push(len as i32)          // OK: stack preserved

// PASS: structured concurrency
async fn test_scope:
    async scope s =>
        s.track(fetch_data("http://a.com"))
        s.track(fetch_data("http://b.com"))

// PASS: task is storable
fn test:
    let task = fetch_data("http://example.com")
    var tasks = Vec.new()
    tasks.push(task)               // OK: Task[T] is storable

// PASS: error propagation with await
async fn load(url: str) -> Result[Config, AppError]:
    let text = fetch_data(url).await?
    json.decode(text)?

// FAIL: async in no_runtime build
// (when with.toml has runtime = false)
async fn bad -> i32: 42        // ERROR: async requires fiber runtime
