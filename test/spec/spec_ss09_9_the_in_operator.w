// Spec test: Section 9.9 — The `in` Operator
//
// `x in collection` is a boolean membership test (the Contains trait). The
// compiler optimizes literal cases (array literals, ranges) to zero-allocation
// comparison chains, and desugars collection cases to `collection.contains(x)`.
// `x not in collection` is its negation.
//
// Covered here (executable): array-literal membership, `not in`, integer and
// char ranges, substring-in-string, char-in-string, Vec / HashMap / HashSet
// membership, enum-variant-in-array, compound conditions, the literal-array
// optimization's semantic equivalence, and the distinction between a `for ... in`
// loop and a membership `in` test.
//
// Deferred to follow-up issues (not yet implemented):
//   - membership over a fixed-size array *variable* (`x in some_array_var`)
//   - `in` patterns in match arms (`in [...]:`) and `@ in` range bindings
//   - membership filters inside comprehensions / pipeline `filter`
//   - user-defined `Contains[T]` trait dispatch
//   - negative cases (`in` requires Contains; `in` is non-associative)

enum Color { Red | Green | Blue | Yellow }

// Basic array membership — optimized to an equality chain.
fn test_array_literal_membership:
    let x = 3
    assert(x in [1, 2, 3, 4, 5])
    assert(not (x in [6, 7, 8]))

// The `not in` operator negates membership.
fn test_not_in_operator:
    let x = 10
    assert(x not in [1, 2, 3])
    assert(not (x not in [10, 20, 30]))

// Integer range membership respects exclusive vs inclusive bounds.
fn test_range_membership:
    assert(5 in 1..10)
    assert(not (10 in 1..10))     // exclusive upper bound
    assert(10 in 1..=10)          // inclusive upper bound
    assert(not (0 in 1..10))

// Char range membership (chars lower to ints).
fn test_char_in_range:
    let c = 'k'
    assert(c in 'a'..='z')
    assert('K' not in 'a'..='z')

// `"sub" in str` tests substring containment.
fn test_string_substring:
    let text = "hello world"
    assert("hello" in text)
    assert("xyz" not in text)

// `ch in str` tests byte/codepoint membership.
fn test_char_in_string:
    let email = "user@example.com"
    assert('@' in email)
    assert('!' not in email)

// Vec membership via the Contains trait.
fn test_vec_membership:
    var names: Vec[str] = Vec.new()
    names.push("alice")
    names.push("bob")
    assert("alice" in names)
    assert("charlie" not in names)

// HashMap key membership.
fn test_hashmap_key_membership:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alice", 1)
    map.insert("bob", 2)
    assert("alice" in map)
    assert("charlie" not in map)

// HashSet membership.
fn test_hashset_membership:
    var set: HashSet[i32] = HashSet.new()
    set.insert(10)
    set.insert(20)
    assert(10 in set)
    assert(30 not in set)

// Enum variant shorthand inside an array literal.
fn test_enum_variant_in_array:
    let c = Color.Red
    assert(c in [.Red, .Green, .Blue])
    assert(c not in [.Yellow])

// `in` composes with other boolean operators.
fn test_compound_conditions:
    let role = "admin"
    let action = "delete"
    assert(role in ["admin", "moderator"] and action in ["read", "write", "delete"])

// The literal-array optimization is semantically equal to the OR chain.
fn test_literal_array_optimization:
    let x = "filter"
    let a = x in ["map", "filter", "reduce"]
    let b = x == "map" or x == "filter" or x == "reduce"
    assert(a == b)

// A `for ... in` loop (Iter) is distinct from a membership `in` test (Contains).
fn test_for_in_distinct_from_membership:
    let items = [1, 2, 3, 4, 5]
    var count = 0
    for x in items:             // for-in loop
        if x in [2, 4]:         // membership test
            count += 1
    assert(count == 2)
