//! expect-stdout: ok

// Trie[V] over the c-algorithms trie (docs/stdlib_sourcing_plan.md Phase 1):
// insert/replace, observing lookups, transfers, prefix traversal in key
// order, and exactly-once drops of Drop-class values.

use std.builtins.print_i32
use std.collections.trie.Trie

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var trie = Trie[i32].new()
    assert(trie.is_empty() and trie.get("").is_none())
    assert(trie.insert("car", 1).is_none())
    assert(trie.insert("cart", 2).is_none())
    assert(trie.insert("cat", 3).is_none())
    assert(trie.insert("dog", 4).is_none())
    assert(trie.insert("", 5).is_none())
    assert(trie.len() == 5)
    assert(*trie.get("cat").unwrap() == 3)
    assert(*trie.get("").unwrap() == 5)
    assert(trie.get("ca").is_none() and not trie.contains("do"))
    assert(trie.insert("cat", 30).unwrap() == 3)
    assert(*trie.get("cat").unwrap() == 30 and trie.len() == 5)
    var under_ca = trie.iter_prefix("ca")
    var seen = [0, 0, 0]
    var count = 0
    while let Some(v) = under_ca.next():
        seen[count] = *v
        count = count + 1
    assert(count == 3 and seen[0] == 1 and seen[1] == 2 and seen[2] == 30)
    var none = trie.iter_prefix("zebra")
    assert(none.next().is_none())
    var all = trie.iter()
    var total = 0
    while let Some(v) = all.next():
        total = total + *v
    assert(total == 42)
    assert(trie.remove("car").unwrap() == 1)
    assert(trie.remove("car").is_none())
    assert(trie.get("cart").unwrap() == 2 and trie.len() == 4)

fn drops(slot: *mut i32):
    var trie = Trie[Tag].new()
    assert(trie.insert("a", Tag { id: 1, slot }).is_none())
    assert(trie.insert("ab", Tag { id: 2, slot }).is_none())
    assert(trie.insert("b", Tag { id: 4, slot }).is_none())
    let replaced = trie.insert("b", Tag { id: 8, slot }).unwrap()
    assert(replaced.id == 4)
    drop(replaced)
    let removed = trie.remove("ab").unwrap()
    assert(removed.id == 2)
    drop(removed)

fn main:
    ints()
    var counter = 0
    drops(&raw mut counter)
    assert(counter == 15)
    print("ok")
