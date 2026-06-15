//! expect-stdout: ok
// Spec test: §13.3 collect[C] target selection.

fn numbers() -> Vec[i32]:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs

fn pairs() -> Vec[(str, i32)]:
    let xs: Vec[(str, i32)] = Vec.new()
    xs.push(("a", 1))
    xs.push(("b", 2))
    xs.push(("a", 3))
    xs

fn bytes() -> Vec[u8]:
    let xs: Vec[u8] = Vec.new()
    xs.push(65)
    xs.push(66)
    xs.push(67)
    xs

fn test_collect_vec:
    let xs = numbers()
    let copied = xs.iter().collect[Vec[i32]]()
    assert(copied.len() == 3)
    assert(copied.get(0) == 1)
    assert(copied.get(1) == 2)
    assert(copied.get(2) == 3)

fn test_collect_hashset:
    let xs = numbers()
    let set: HashSet[i32] = xs.iter() |> collect[HashSet[i32]]()
    assert(set.contains(1))
    assert(set.contains(2))
    assert(set.contains(3))
    assert(not set.contains(4))

fn test_collect_hashmap:
    let xs = pairs()
    let map: HashMap[str, i32] = xs.iter() |> collect[HashMap[str, i32]]()
    assert(map.get("a").unwrap() == 3)
    assert(map.get("b").unwrap() == 2)
    assert(map.get("missing").is_none())

fn test_collect_string:
    let xs = bytes()
    let text: str = xs.iter() |> collect[String]()
    assert(text == "ABC")

fn main:
    test_collect_vec()
    test_collect_hashset()
    test_collect_hashmap()
    test_collect_string()
    print("ok")
