// STC engine benchmark (docs/proposals/stdlib_sourcing_plan.md, Phase 3: the
// facade map's primary engines against the comparison engines, under one
// compilation). Each facade owns its values and reaches the engine through
// slot pointers, so the comparison measures the whole facade. Prints
// nanoseconds per operation (median of three rounds).
//
//     with run test/benchmark/stc_engines.w

use std.collections
use std.collections.priority_queue.PriorityQueue
use std.collections.binary_heap.BinaryHeap
use std.collections.ordered_set.OrderedSet
use std.collections.sorted_list.SortedList
use std.collections.deque.Deque
use std.collections.unordered_set.UnorderedSet
use std.collections.stack.Stack
use std.collections.queue.Queue
use std.collections.linked_list.LinkedList
use std.algorithms
use std.time
use std.builtins

type Timing { insert: i64, lookup: i64, remove: i64 }

// A two-field record: not a word, so the deque's slot shape.
type Pair { a: i32, b: i32 }

fn pqueue_round(n: i32) -> Timing:
    var queue = PriorityQueue[i32].new()
    let t0 = now_ns()
    for i in 0..n: queue.push(if i % 2 == 0: i else: n - i)
    let t1 = now_ns()
    var peeks: i64 = 0
    for i in 0..n: peeks = peeks + *queue.peek().unwrap() as i64
    let t2 = now_ns()
    for i in 0..n: assert(queue.pop().is_some())
    let t3 = now_ns()
    assert(queue.is_empty() and peeks > 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn heap_round(n: i32) -> Timing:
    var heap = BinaryHeap[i32].new()
    let t0 = now_ns()
    for i in 0..n: heap.push(if i % 2 == 0: i else: n - i)
    let t1 = now_ns()
    var peeks: i64 = 0
    for i in 0..n: peeks = peeks + *heap.peek().unwrap() as i64
    let t2 = now_ns()
    for i in 0..n: assert(heap.pop().is_some())
    let t3 = now_ns()
    assert(heap.is_empty() and peeks > 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn ordered_set_round(n: i32) -> Timing:
    var set = OrderedSet[i32].new()
    let t0 = now_ns()
    for i in 0..n: assert(set.insert((i * 7919) % n))
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if set.contains(&i): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(set.remove(&i).is_some())
    let t3 = now_ns()
    assert(hits == n and set.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn btree_map_round(n: i32) -> Timing:
    var map = BTreeMap[i32, i32].new()
    let t0 = now_ns()
    for i in 0..n: map.insert((i * 7919) % n, i)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if map.contains(&i): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(map.remove(&i).is_some())
    let t3 = now_ns()
    assert(hits == n and map.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

// The slot shape: a `str` key rides a facade-owned slot and the With
// comparator (D148); the keys are fixed-width so their order is numeric.
fn btree_map_str_round(n: i32) -> Timing:
    var map = BTreeMap[str, i32].new()
    let t0 = now_ns()
    for i in 0..n: map.insert(f"{(i * 7919) % n:08}", i)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if map.contains(&f"{i:08}"): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(map.remove(&f"{i:08}").is_some())
    let t3 = now_ns()
    assert(hits == n and map.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn btree_set_str_round(n: i32) -> Timing:
    var set = BTreeSet[str].new()
    let t0 = now_ns()
    for i in 0..n: set.insert(f"{(i * 7919) % n:08}")
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if set.contains(&f"{i:08}"): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(set.remove(&f"{i:08}"))
    let t3 = now_ns()
    assert(hits == n and set.len() == 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn sorted_list_round(n: i32) -> Timing:
    var sorted = SortedList[i32].new()
    let t0 = now_ns()
    for i in 0..n: sorted.insert((i * 7919) % n)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if sorted.contains(&i): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: sorted.remove(0)
    let t3 = now_ns()
    assert(hits == n and sorted.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn btree_set_round(n: i32) -> Timing:
    var set = BTreeSet[i32].new()
    let t0 = now_ns()
    for i in 0..n: set.insert((i * 7919) % n)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if set.contains(i): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: set.remove(i)
    let t3 = now_ns()
    assert(hits == n and set.len() == 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn deque_round(n: i32) -> Timing:
    var d = Deque[i32].new()
    let t0 = now_ns()
    for i in 0..n:
        if i % 2 == 0: d.push_back(i) else: d.push_front(i)
    let t1 = now_ns()
    var sum: i64 = 0
    for i in 0..n: sum = sum + *d.get(i as isize) as i64
    let t2 = now_ns()
    for i in 0..(n / 2):
        assert(d.pop_front().is_some())
        assert(d.pop_back().is_some())
    let t3 = now_ns()
    assert(sum > 0 and d.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn deque_slots_round(n: i32) -> Timing:
    // A record is not a word: the slot shape, one allocation each.
    var d = Deque[Pair].new()
    let t0 = now_ns()
    for i in 0..n:
        if i % 2 == 0: d.push_back(Pair { a: i, b: i }) else: d.push_front(Pair { a: i, b: i })
    let t1 = now_ns()
    var sum: i64 = 0
    for i in 0..n: sum = sum + d.get(i as isize).a as i64
    let t2 = now_ns()
    for i in 0..(n / 2):
        assert(d.pop_front().is_some())
        assert(d.pop_back().is_some())
    let t3 = now_ns()
    assert(sum > 0 and d.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn unordered_set_round(n: i32) -> Timing:
    var set = UnorderedSet[i32].new()
    let t0 = now_ns()
    for i in 0..n: assert(set.insert(i * 7919 % n))
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if set.contains(&i): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(set.remove(&i).is_some())
    let t3 = now_ns()
    assert(hits == n and set.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn hashset_round(n: i32) -> Timing:
    var set = HashSet[i32].new()
    let t0 = now_ns()
    for i in 0..n: set.insert(i * 7919 % n)
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if set.contains(i): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: set.remove(i)
    let t3 = now_ns()
    assert(hits == n and set.len() == 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn list_ends_round(n: i32) -> Timing:
    var xs: List[i32] = []
    let t0 = now_ns()
    for i in 0..n: xs.push(i)
    let t1 = now_ns()
    var sum: i64 = 0
    for i in 0..n: sum = sum + xs[i] as i64
    let t2 = now_ns()
    for i in 0..n: assert(xs.pop().is_some())
    let t3 = now_ns()
    assert(sum > 0 and xs.len() == 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn sort_round(n: i32) -> Timing:
    var words: List[i64] = []
    for i in 0..n: words.push(((i as i64) * 7919) % (n as i64))
    let t0 = now_ns()
    words.sort()
    let t1 = now_ns()
    var pairs: List[(i32, i32)] = []
    for i in 0..n: pairs.push(((i * 7919) % n, i))
    let t2 = now_ns()
    pairs.sort_by((a, b) => if a.0 < b.0: -1 else if a.0 > b.0: 1 else: 0)
    let t3 = now_ns()
    for i in 1..n: assert(words[i - 1] <= words[i] and pairs[i - 1].0 <= pairs[i].0)
    Timing { insert: t1 - t0, lookup: t3 - t2, remove: 0 }

fn stable_sort_round(n: i32) -> Timing:
    var words: List[i64] = []
    for i in 0..n: words.push(((i as i64) * 7919) % (n as i64))
    let t0 = now_ns()
    words.stable_sort()
    let t1 = now_ns()
    var pairs: List[(i32, i32)] = []
    for i in 0..n: pairs.push(((i * 7919) % n, i))
    let t2 = now_ns()
    pairs.stable_sort_by((a, b) => if a.0 < b.0: -1 else if a.0 > b.0: 1 else: 0)
    let t3 = now_ns()
    for i in 1..n: assert(words[i - 1] <= words[i] and pairs[i - 1].0 <= pairs[i].0)
    Timing { insert: t1 - t0, lookup: t3 - t2, remove: 0 }

// The slot shape of the priority queue: a min-queue of i32 (the word heap
// serves only the max-queue of a signed word).
fn pqueue_slots_round(n: i32) -> Timing:
    var queue = PriorityQueue[i32].new_min()
    let t0 = now_ns()
    for i in 0..n: queue.push(if i % 2 == 0: i else: n - i)
    let t1 = now_ns()
    var peeks: i64 = 0
    for i in 0..n: peeks = peeks + *queue.peek().unwrap() as i64
    let t2 = now_ns()
    for i in 0..n: assert(queue.pop().is_some())
    let t3 = now_ns()
    assert(queue.is_empty() and peeks >= 0)
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

// The slot shape of the unordered set: a record key.
fn unordered_set_slots_round(n: i32) -> Timing:
    var set = UnorderedSet[Pair].new()
    let t0 = now_ns()
    for i in 0..n: assert(set.insert(Pair { a: i * 7919 % n, b: 0 }))
    let t1 = now_ns()
    var hits = 0
    for i in 0..n:
        if set.contains(&Pair { a: i, b: 0 }): hits = hits + 1
    let t2 = now_ns()
    for i in 0..n: assert(set.remove(&Pair { a: i, b: 0 }).is_some())
    let t3 = now_ns()
    assert(hits == n and set.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn stack_round(n: i32) -> Timing:
    var s = Stack[i32].new()
    let t0 = now_ns()
    for i in 0..n: s.push(i)
    let t1 = now_ns()
    var sum: i64 = 0
    for i in 0..n: sum = sum + *s.get(i as isize) as i64
    let t2 = now_ns()
    for i in 0..n: assert(s.pop().is_some())
    let t3 = now_ns()
    assert(sum > 0 and s.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn stack_slots_round(n: i32) -> Timing:
    var s = Stack[Pair].new()
    let t0 = now_ns()
    for i in 0..n: s.push(Pair { a: i, b: i })
    let t1 = now_ns()
    var sum: i64 = 0
    for i in 0..n: sum = sum + s.get(i as isize).a as i64
    let t2 = now_ns()
    for i in 0..n: assert(s.pop().is_some())
    let t3 = now_ns()
    assert(sum > 0 and s.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn queue_round(n: i32) -> Timing:
    var q = Queue[i32].new()
    let t0 = now_ns()
    for i in 0..n: q.push(i)
    let t1 = now_ns()
    var sum: i64 = 0
    var cursor = q.iter()
    while let Some(v) = cursor.next(): sum = sum + *v as i64
    let t2 = now_ns()
    for i in 0..n: assert(q.pop().is_some())
    let t3 = now_ns()
    assert(sum > 0 and q.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn linked_list_round(n: i32) -> Timing:
    var l = LinkedList[i32].new()
    let t0 = now_ns()
    for i in 0..n:
        if i % 2 == 0: l.push_back(i) else: l.push_front(i)
    let t1 = now_ns()
    var sum: i64 = 0
    var cursor = l.iter()
    while let Some(v) = cursor.next(): sum = sum + *v as i64
    let t2 = now_ns()
    for i in 0..n: assert(l.pop_front().is_some())
    let t3 = now_ns()
    assert(sum > 0 and l.is_empty())
    Timing { insert: t1 - t0, lookup: t2 - t1, remove: t3 - t2 }

fn median(a: i64, b: i64, c: i64) -> i64:
    if a < b:
        if b < c: b else if a < c: c else: a
    else:
        if a < c: a else if b < c: c else: b

fn report(name: &str, round: fn(i32) -> Timing, n: i32):
    let a = round(n)
    let b = round(n)
    let c = round(n)
    let insert = median(a.insert, b.insert, c.insert) / n
    let lookup = median(a.lookup, b.lookup, c.lookup) / n
    let remove = median(a.remove, b.remove, c.remove) / n
    print(f"{name}\t{insert}\t{lookup}\t{remove}")

let n = 100000
print(f"engine\tinsert_ns\tlookup_ns\tremove_ns\t(n={n}, i32 values, median of 3)")
report("PriorityQueue[i32] (STC pqueue, word shape)", pqueue_round, n)
report("PriorityQueue[i32] min (STC pqueue, slot shape)", pqueue_slots_round, n)
report("BinaryHeap (c-algorithms)", heap_round, n)
report("OrderedSet (STC sset)", ordered_set_round, n)
report("BTreeSet[i32] (M*LIB bptree, word shape)", btree_set_round, n)
report("BTreeMap[i32] (M*LIB bptree, word shape)", btree_map_round, n)
report("BTreeSet[str] (M*LIB bptree, slot shape)", btree_set_str_round, n)
report("BTreeMap[str] (M*LIB bptree, slot shape)", btree_map_str_round, n)
report("SortedList (c-algorithms, remove(0))", sorted_list_round, 20000)
report("Deque[i32] (STC deque, word shape)", deque_round, n)
report("Deque[Pair] (STC deque, slot shape)", deque_slots_round, n)
report("Stack[i32] (STC stack, word shape)", stack_round, n)
report("Stack[Pair] (STC stack, slot shape)", stack_slots_round, n)
report("Queue[i32] push/iter/pop (STC queue, word shape)", queue_round, n)
report("LinkedList[i32] push/iter/pop_front (STC list, word shape)", linked_list_round, n)
report("List push/index/pop (rt_core)", list_ends_round, n)
report("UnorderedSet[i32] (STC hset, word shape)", unordered_set_round, n)
report("UnorderedSet[Pair] (STC hset, slot shape)", unordered_set_slots_round, n)
report("HashSet (rt_core, insertion-ordered)", hashset_round, n)
print("sort\tsort_i64_ns\tsort_by_pair_ns\t-")
report("List.sort (STC sort)", sort_round, n)
report("List.stable_sort (merge sort over references)", stable_sort_round, n)


