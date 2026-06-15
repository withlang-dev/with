//! expect-stdout: ok
// Spec test: §4.3c collection literals.

fn test_fixed_array_default:
    let xs = [1, 2, 3]
    assert(xs[0] == 1)
    assert(xs[1] == 2)
    assert(xs[2] == 3)

fn test_vec_expected_type:
    let xs: Vec[i32] = [1, 2, 3]
    assert(xs.len() == 3)
    assert(xs.get(0) == 1)
    assert(xs.get(1) == 2)
    assert(xs.get(2) == 3)

    let empty: Vec[i32] = []
    assert(empty.len() == 0)

fn test_hashset_expected_type:
    let values: HashSet[str] = ["red", "green", "red"]
    assert(values.contains("red"))
    assert(values.contains("green"))
    assert(not values.contains("blue"))

fn test_hashmap_default_and_empty:
    let colors = ["red": 1, "green": 2, "red": 3]
    assert(colors.get("red").unwrap() == 3)
    assert(colors.get("green").unwrap() == 2)
    assert(colors.get("blue").is_none())

    let empty: HashMap[str, i32] = [:]
    assert(empty.get("red").is_none())

fn main:
    test_fixed_array_default()
    test_vec_expected_type()
    test_hashset_expected_type()
    test_hashmap_default_and_empty()
    print("ok")
