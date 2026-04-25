//! skip
// Spec test: Section 9.9 — The `in` Operator (formerly 25.100)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic array membership
fn test:
    let x = 3
    assert(x in [1, 2, 3, 4, 5])
    assert(not (x in [6, 7, 8]))

// PASS: not in operator
fn test:
    let x = 10
    assert(x not in [1, 2, 3])
    assert(not (x not in [10, 20, 30]))

// PASS: range membership
fn test:
    assert(5 in 1..10)
    assert(not (10 in 1..10))     // exclusive upper bound
    assert(10 in 1..=10)          // inclusive upper bound
    assert(not (0 in 1..10))

// PASS: string contains substring
fn test:
    let text = "hello world"
    assert("hello" in text)
    assert("xyz" not in text)

// PASS: char in string
fn test:
    let email = "user@example.com"
    assert('@' in email)
    assert('!' not in email)

// PASS: HashMap key membership
fn test:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alice", 1)
    map.insert("bob", 2)
    assert("alice" in map)
    assert("charlie" not in map)

// PASS: HashSet membership
fn test:
    var set: HashSet[i32] = HashSet.new()
    set.insert(10)
    set.insert(20)
    assert(10 in set)
    assert(30 not in set)

// PASS: enum variant shorthand in array
fn test:
    enum Color { Red | Green | Blue | Yellow }
    let c = Color.Red
    assert(c in [.Red, .Green, .Blue])
    assert(c not in [.Yellow])

// PASS: in with pipeline filter
fn test:
    let nums = Vec.from([1, 2, 3, 4, 5, 6])
    let evens = nums.iter()
        |> filter(x => *x in [2, 4, 6])
        |> collect[Vec]()
    assert(evens.len() == 3)

// PASS: match with in patterns
fn test:
    let method = "map"
    let result = match method:
        in ["map", "filter", "take"] => "lazy"
        in ["collect", "fold", "sum"] => "eager"
        _ => "other"
    assert(result == "lazy")

// PASS: match with in pattern and @ binding
fn test:
    let code = 404
    let msg = match code:
        c @ in 200..=299 => "ok: {c}"
        c @ in 400..=499 => "client error: {c}"
        _ => "other"
    assert(msg == "client error: 404")

// PASS: user type implementing Contains
fn test:
    type Whitelist { allowed: HashSet[i32] }
    impl Contains[i32] for Whitelist =
        fn contains(self: &Self, value: &i32) -> bool:
            *value in self.allowed
    var wl = Whitelist { allowed: HashSet.from([1, 2, 3]) }
    assert(1 in wl)
    assert(4 not in wl)

// PASS: in with compound conditions
fn test:
    let role = "admin"
    let action = "delete"
    let allowed = ["read", "write", "delete"]
    assert(role in ["admin", "moderator"] and action in allowed)

// PASS: literal array optimization (semantic equivalence)
fn test:
    let x = "filter"
    // These should produce identical results
    let a = x in ["map", "filter", "reduce"]
    let b = x == "map" or x == "filter" or x == "reduce"
    assert(a == b)

// FAIL: in requires Contains implementation
fn test:
    type Foo { x: i32 }
    type Bar { y: i32 }
    let f = Foo { x: 1 }
    let b = Bar { y: 2 }
    f in b              // ERROR: `Bar` does not implement `Contains[Foo]`

// FAIL: in is non-associative
fn test:
    let x = 1
    x in [1, 2] in [true, false]   // ERROR: `in` is non-associative

// PASS: for-in loop is distinct from membership in
fn test:
    let items = [1, 2, 3, 4, 5]
    var count = 0
    for x in items:             // for-in loop (Iter trait)
        if x in [2, 4]:        // membership test (Contains trait)
            count += 1
    assert(count == 2)

// PASS: comprehension with membership filter
fn test:
    let primes = HashSet.from([2, 3, 5, 7, 11, 13])
    let prime_squares = [x * x for x in 1..=15 if x in primes]
    assert(prime_squares.len() == 6)
