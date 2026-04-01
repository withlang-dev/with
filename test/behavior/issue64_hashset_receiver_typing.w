//! check-only

fn shared_contains(set: &HashSet[i32]) -> bool:
    set.contains(1)

fn mutable_insert(set: &mut HashSet[i32]):
    set.insert(1)

fn mutable_remove(set: &mut HashSet[i32]) -> bool:
    set.remove(1)

fn value_contains(set: HashSet[i32]) -> bool:
    set.contains(2)

fn main:
    let set: HashSet[i32] = HashSet.new()
    assert(not shared_contains(&set))
