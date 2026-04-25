//! skip
// Spec test: Section 13.4 — Generators (formerly 25.16)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic
gen fn countdown(from: i32) -> i32:
    var i = from
    while i >= 0: yield i; i -= 1

fn test:
    let result = countdown(3) |> collect[Vec]()
    assert(result == vec![3, 2, 1, 0])

// PASS: infinite with take
gen fn naturals -> Int:
    var n = 0
    loop: yield n; n += 1

fn test:
    let first_5 = naturals() |> take(5) |> collect[Vec]()
    assert(first_5 == vec![0, 1, 2, 3, 4])

// PASS: compose with pipeline
gen fn fibonacci -> Int:
    var a = 0; var b = 1
    loop: yield a; let n = a + b; a = b; b = n

fn test:
    let even_fibs = fibonacci()
        |> take_while(x => x < 100)
        |> filter(x => x % 2 == 0)
        |> collect[Vec]()
    assert(even_fibs == vec![0, 2, 8, 34])
