use std.collections

// This runtime-layout fixture inspects capacity without adding a public API.
fn runtime_capacity(map: &SlotMap[i32]): unsafe *((map.ptr as i64 + 32) as *const i64) as i32

fn test_fifo_reuses_every_free_slot_before_returning_to_one:
    var map = SlotMap[i32].new()
    let first = map.insert(0)
    let capacity = runtime_capacity(map)
    assert(map.remove(first).unwrap() == 0)
    for i in 1..capacity:
        let next = map.insert(i)
        assert(next.index != first.index)
        assert(map.remove(next).unwrap() == i)
        assert(not map.contains(next))
    let reused = map.insert(42)
    assert(reused.index == first.index)
    assert(reused.generation != first.generation)
    assert(map.get(first).is_none())
    assert(map.get(reused).unwrap() == 42)

fn test_fifo_growth_and_removal_order:
    var map = SlotMap[i32].new()
    let handles: Vec[Handle[i32]] = Vec.new()
    for i in 0..128: handles.push(map.insert(i))
    assert(runtime_capacity(map) == 128)
    for i in [71, 3, 99, 0]: assert(map.remove(handles[i]).unwrap() == i)
    for i in [71, 3, 99, 0]:
        let replacement = map.insert(1000 + i)
        assert(replacement.index == handles[i].index)
        assert(replacement.generation != handles[i].generation)
        assert(map.get(handles[i]).is_none())
        assert(map.get(replacement).unwrap() == 1000 + i)
    let after_growth = map.insert(128)
    assert(runtime_capacity(map) > 128 and map.len() == 129)
    assert(map.get(after_growth).unwrap() == 128)
    for i in 0..128:
        if i != 71 and i != 3 and i != 99 and i != 0:
            assert(map.get(handles[i]).unwrap() == i)

fn test_generation_exhaustion_retires_slot:
    var map = SlotMap[i32].new()
    var last = map.insert(7)
    let original = last
    // Runtime-layout fixture: reaching the boundary by billions of inserts
    // would hide the property this checks. The public handle API stays intact.
    last.generation = 4294967295
    unsafe:
        let generations = *((map.ptr as i64 + 16) as *const *mut u32)
        *generations = last.generation
    assert(map.remove(last).unwrap() == 7)
    for i in 0..64:
        let current = map.insert(i)
        assert(current.index != original.index)
        assert(not map.contains(original) and not map.contains(last))
        assert(map.remove(current).unwrap() == i)
    // Retirement can leave len < cap with no reusable slot. Inserting live
    // values must still grow once all remaining slots have been filled.
    for i in 0..32:
        let current = map.insert(i)
        assert(current.index != original.index)
        assert(map.get(current).unwrap() == i)
    assert(map.len() == 32 and not map.contains(last))
