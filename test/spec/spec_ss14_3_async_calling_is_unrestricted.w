//! skip
// Spec test: Section 14.3 — Async Calling Is Unrestricted (formerly 25.18)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: any function can call an async fn (gets Task[T] back)
fn regular_function:
    let task = fetch_data("http://example.com")
    // task is Task[Result[String, IoError]]
    // can store it, pass it around
    let result = task.await
    print(result)

// WARNING: let _ = ... immediately CANCELS the task
fn bad_fire_and_forget:
    let _ = send_analytics("page_view")
    // WARNING: task is dropped — fiber is cancelled immediately!
    // Use `spawn` for true fire-and-forget

// PASS: fire-and-forget (spawn, runs to completion)
fn fire_and_forget:
    spawn send_analytics("page_view")
    // task runs in background, detached, not tied to caller

// PASS: store tasks, compose them as values
fn test:
    let tasks = urls
        |> map(u => fetch_data(u))  // no .await here — just Task values
        |> collect[Vec]()
    let results = tasks
        |> map(t => t.await)
        |> collect[Vec]()

// PASS: async fn in trait (just works)
trait DataSource:
    async fn fetch(self: &Self, id: i32) -> Result[Data, Error]

impl DataSource for RemoteDb:
    async fn fetch(self: &RemoteDb, id: i32) -> Result[Data, Error]:
        let row = self.conn.query(id).await
        Ok(row.into_data())

// No boxing, no GATs, no special handling.
// async fn in traits returns Task[T] like any other async fn.
