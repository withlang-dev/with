//! check-only

fn shared_contains(set: &HashSet[i32]) -> bool:
    set.contains(1)

fn value_contains(set: HashSet[i32]) -> bool:
    set.contains(2)

fn main:
    let set: HashSet[i32] = HashSet.new()
    assert(not shared_contains(&set))
