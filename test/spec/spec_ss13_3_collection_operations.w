//! skip
// Spec test: Section 13.3 — Collection Operations (formerly 25.15)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: reduce
fn test:
    let sum = vec![1, 2, 3, 4].iter() |> reduce((a, b) => a + b)
    assert(sum == Some(10))

// PASS: fold
fn test:
    let sum = vec![1, 2, 3].iter() |> fold(0, (acc, x) => acc + x)
    assert(sum == 6)

// PASS: flat_map
fn test:
    let words = vec!["hello world", "foo bar"].iter()
        |> flat_map(s => s.split(' '))
        |> collect[Vec]()
    assert(words.len() == 4)

// PASS: zip
fn test:
    let pairs = vec![1, 2].iter()
        |> zip(vec!["a", "b"].iter())
        |> collect[Vec]()
    assert(pairs == vec![(1, "a"), (2, "b")])

// PASS: partition
fn test:
    let (evens, odds) = vec![1, 2, 3, 4].iter()
        |> partition(x => x % 2 == 0)
    assert(evens == vec![2, 4])

// PASS: complex pipeline
fn test:
    let result = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10].iter()
        |> filter(x => x % 2 == 0)
        |> map(x => x * x)
        |> take(3)
        |> sum()
    assert(result == 56)
