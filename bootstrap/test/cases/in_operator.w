// Test: in / not in operator (§9.9)
fn main -> i32:
    // --- Array literal membership (integer) ---
    let x = 3
    assert(x in [1, 2, 3, 4, 5])
    assert(not (x in [6, 7, 8]))

    // --- not in operator ---
    assert(x not in [10, 20, 30])
    assert(not (x not in [1, 2, 3]))

    // --- Range membership (exclusive) ---
    assert(5 in 1..10)
    assert(not (10 in 1..10))     // exclusive upper bound
    assert(not (0 in 1..10))

    // --- Range membership (inclusive) ---
    assert(10 in 1..=10)
    assert(1 in 1..=10)
    assert(not (0 in 1..=10))
    assert(not (11 in 1..=10))

    // --- Range not in ---
    assert(0 not in 1..10)
    assert(10 not in 1..10)
    assert(not (5 not in 1..10))

    // --- String contains ---
    let text = "hello world"
    assert("hello" in text)
    assert("world" in text)
    assert("xyz" not in text)

    // --- Array literal membership (string) ---
    let method = "filter"
    assert(method in ["map", "filter", "reduce"])
    assert(method not in ["collect", "fold", "sum"])

    // --- Compound conditions ---
    let a = 2
    let b = 4
    assert(a in [1, 2, 3] and b in [4, 5, 6])
    assert(not (a in [10, 20] and b in [4, 5, 6]))

    // --- Empty array ---
    assert(not (1 in []))

    // --- Precedence: arithmetic binds tighter ---
    assert(1 + 1 in [2, 3, 4])

    // --- for-in loop still works ---
    var sum = 0
    for i in 1..=5:
        if i in [2, 4]:
            sum = sum + i
    assert(sum == 6)

    println("all in-operator tests passed")
