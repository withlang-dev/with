//! skip
// Spec test: Section 14.13 — Await Inside Iterators (formerly 25.58)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: .await inside map closure
async fn test:
    let urls = vec!["http://a.com", "http://b.com"]
    let results = urls.iter()
        |> map(url => fetch(url).await)
        |> collect[Vec]()
    assert(results.len() == 2)

// PASS: .await inside fold
async fn test:
    let ids = vec![1, 2, 3]
    let total = ids.iter()
        |> fold(0, (sum, id) => sum + get_count(id).await)
    assert(total > 0)
