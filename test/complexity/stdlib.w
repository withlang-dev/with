use std.collections
use std.time
use std.process
use std.builtins

fn slotmap_work(n: i32):
    var slots = SlotMap[i32].new()
    let handles: Vec[Handle[i32]] = Vec.new()
    for i in 0..n: handles.push(slots.insert(i))
    for i in 0..n:
        if i % 2 == 0: assert(slots.remove(handles[i]).unwrap() == i)
    for i in 0..(n / 2): slots.insert(n + i)
    for i in 0..n:
        if i % 2 == 0: assert(slots.get(handles[i]).is_none())
        else: assert(slots.get(handles[i]).unwrap() == i)
    assert(slots.len() == n)
    n

fn vec_work(n: i32):
    let values: Vec[i32] = Vec.new()
    for i in 0..n: values.push(i)
    var sum = 0
    for i in 0..n:
        assert(values[i] == i)
        sum = sum + values[i]
    assert(sum == n * (n - 1) / 2)
    for i in 0..n: assert(values.pop().unwrap() == n - i - 1)
    sum

fn borrowed_work(n: i32):
    let values: Vec[i32] = Vec.new()
    for i in 0..n: values.push(i)
    var iterator = values.iter()
    var sum = 0
    var count = 0
    while let Some(value) = iterator.next():
        assert(value == count)
        sum = sum + value
        count = count + 1
    assert(count == n and values.len() == n)
    assert(sum == n * (n - 1) / 2)
    sum

fn consuming_work(n: i32):
    let values: Vec[i32] = Vec.new()
    for i in 0..n: values.push(i)
    var iterator = values.into_iter()
    var sum = 0
    var count = 0
    while let Some(value) = iterator.next():
        assert(value == count)
        sum = sum + value
        count = count + 1
    assert(count == n)
    assert(sum == n * (n - 1) / 2)
    sum

fn hashmap_work(n: i32):
    var entries = HashMap[i32, i32].new()
    for i in 0..n: entries.insert(i, i)
    for i in 0..n: assert(entries.get(i).unwrap() == i)
    for i in 0..n:
        if i % 2 == 0: assert(entries.remove(i).unwrap() == i)
    for i in 0..n:
        if i % 2 == 0: assert(entries.get(i).is_none())
        else: assert(entries.get(i).unwrap() == i)
    assert(entries.len() == n / 2)
    n

fn hashset_work(n: i32):
    var entries = HashSet[i32].new()
    for i in 0..n: entries.insert(i)
    for i in 0..n: assert(entries.contains(i))
    for i in 0..n:
        if i % 2 == 0: assert(entries.remove(i))
    for i in 0..n: assert(entries.contains(i) == (i % 2 != 0))
    assert(entries.len() == n / 2)
    n

fn btree_map_work(n: i32, descending: bool):
    var entries = BTreeMap[i32, i32].new()
    for i in 0..n:
        let key = if descending: n - i - 1 else: i
        entries.insert(key, key)
    for i in 0..n: assert(entries.get(i).unwrap() == i)
    for i in 0..n:
        if i % 2 == 0: assert(entries.remove(i).unwrap() == i)
    for i in 0..n:
        if i % 2 == 0: assert(entries.get(i).is_none())
        else: assert(entries.get(i).unwrap() == i)
    assert(entries.len() == n / 2)
    n

fn btree_set_work(n: i32, descending: bool):
    var entries = BTreeSet[i32].new()
    for i in 0..n: entries.insert(if descending: n - i - 1 else: i)
    for i in 0..n: assert(entries.contains(i))
    for i in 0..n:
        if i % 2 == 0: assert(entries.remove(i))
    for i in 0..n: assert(entries.contains(i) == (i % 2 != 0))
    assert(entries.len() == n / 2)
    n

fn btree_map_ascending(n: i32): btree_map_work(n, false)
fn btree_map_descending(n: i32): btree_map_work(n, true)
fn btree_set_ascending(n: i32): btree_set_work(n, false)
fn btree_set_descending(n: i32): btree_set_work(n, true)

fn elapsed(work: fn(i32) -> i32, n: i32):
    let start = now_ns()
    let result = work(n)
    let duration = now_ns() - start
    assert(result > 0 and duration > 0)
    duration

fn median(a: i64, b: i64, c: i64):
    if a < b:
        if b < c: b else if a < c: c else: a
    else:
        if a < c: a else if b < c: c else: b

fn sample(work: fn(i32) -> i32, n: i32):
    median(elapsed(work, n), elapsed(work, n), elapsed(work, n))

fn measure(name: &str, work: fn(i32) -> i32, n: i32, issue: i32):
    let small = sample(work, n)
    let large = sample(work, n * 4)
    let base = if small > 1000000: small else: 1000000
    let within_bound = large <= base * 6 + 1000000
    print(f"{name}\tn={n}\tsmall_ns={small}\tlarge_ns={large}\twithin_bound={within_bound}")
    if issue == 0:
        assert(within_bound)
        print(f"PASS {name}")
    else:
        // A correctness assertion or crash above always fails. Only the
        // measured complexity verdict can be an expected failure.
        if within_bound: print(f"XPASS {name} #{issue}: update the expectation with fix evidence")
        assert(not within_bound)
        print(f"XFAIL {name} #{issue}")

fn allocations:
    eprint("complexity: empty begin")
    eprint("complexity: empty end")
    eprint("complexity: control begin")
    let values: Vec[i32] = Vec.new()
    values.push(42)
    eprint("complexity: control end")
    assert(values[0] == 42)
    var entries = HashMap[i32, i32].new()
    // These i32 keys share the initial bucket in the current FNV/16-slot
    // engine. The correctness check remains valid for replacement engines.
    for key in [0, 64, 128, 192]: entries.insert(key, key + 1)
    eprint("complexity: hash-remove begin")
    let removed = entries.remove(0)
    eprint("complexity: hash-remove end")
    assert(removed.unwrap() == 1)
    assert(entries.len() == 3 and entries.get(0).is_none())
    for key in [64, 128, 192]: assert(entries.get(key).unwrap() == key + 1)
    print("allocation results ok")

if args().len() > 1 and args()[1] == "allocations":
    allocations()
else:
    measure("vec", vec_work, 4000, 0)
    measure("vec-iter", borrowed_work, 4000, 0)
    measure("slotmap", slotmap_work, 2000, 0)
    measure("hashmap", hashmap_work, 4000, 0)
    measure("hashset", hashset_work, 4000, 0)
    measure("vec-into-iter", consuming_work, 4000, 938)
    measure("btree-map-ascending", btree_map_ascending, 1000, 937)
    measure("btree-map-descending", btree_map_descending, 128, 937)
    measure("btree-set-ascending", btree_set_ascending, 1000, 937)
    measure("btree-set-descending", btree_set_descending, 1000, 937)
