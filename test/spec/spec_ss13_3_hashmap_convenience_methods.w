// Spec test: Section 13.3 — HashMap Convenience Methods (formerly 25.98)

fn test_hashmap_update_inserts_default_then_transforms:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.update("alice", 0, n => n + 1)
    assert(counts.get("alice").unwrap() == 1)

fn test_hashmap_update_transforms_existing:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.update("alice", 0, n => n + 1)
    counts.update("alice", 0, n => n + 1)
    assert(counts.get("alice").unwrap() == 2)

fn test_hashmap_update_with_captured_closure:
    var counts: HashMap[str, i32] = HashMap.new()
    let step = 3
    counts.update("alice", 10, n => n + step)
    assert(counts.get("alice").unwrap() == 13)

fn test_hashmap_increment_shorthand:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.increment("bob")
    counts.increment("bob")
    counts.increment("bob")
    assert(counts.get("bob").unwrap() == 3)

fn test_hashmap_decrement_shorthand:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.decrement("bob")
    counts.decrement("bob")
    assert(counts.get("bob").unwrap() == -2)
