//! skip
// Spec test: Section 14.8 — Scoped Task Tracking (formerly 25.53)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: s.track registers task with scope
async fn test:
    async scope s =>
        let t = s.track(fetch_data("http://example.com"))
        let result = t.await
        assert(result.is_ok())

// PASS: ScopedTask is exempt from @[must_use] — scope handles cleanup
async fn test:
    async scope s =>
        s.track(fire_and_forget_in_scope())
        // ScopedTask dropped — no compile error
        // scope will cancel+join it on exit

// PASS: early ? return with ScopedTask — no E0801
async fn test -> Result[i32, AppError]:
    async scope s =>
        let task_a = s.track(compute_a())
        let task_b = s.track(compute_b())
        // If task_a.await? fails, task_b is cancelled by scope
        let a = task_a.await?
        let b = task_b.await?
        Ok(a + b)

// PASS: scatter-gather pattern
async fn test:
    let results = async scope s =>
        let tasks = vec![1, 2, 3].iter()
            |> map(id => s.track(fetch_user(id)))
            |> collect[Vec]()
        tasks |> map(t => t.await) |> collect[Vec]()
    assert(results.len() == 3)

// FAIL: bare Task (not ScopedTask) is still @[must_use]
async fn test_fail:
    fetch_data("http://example.com")    // ERROR E0801: unused Task
