// std.collections.trie — Trie[V]: a prefix-keyed map over the migrated
// c-algorithms trie (docs/stdlib_sourcing_plan.md, Phase 1). Keys are the
// bytes of a `str`; the engine stores one slot pointer per key
// (std.collections.engine_slot) and the facade owns every value.
//
// Complexity contract: O(key length) insert, lookup and remove; prefix
// traversal proportional to the subtree visited.

use std.option
use std.traits
use std.c_algorithms.defs
use std.c_algorithms.trie
use std.collections.engine_slot.Slot
use std.collections.engine_slot.slot_unordered

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

/// A map from string keys to `V` with prefix traversal. `get` observes,
/// `remove` transfers (D27); `insert` returns the value it replaced.
pub type Trie[V] { trie: *mut _Trie }

pub fn Trie.new[V]() -> Trie[V]:
    let trie = trie_new()
    assert(trie as i64 != 0)
    Trie { trie: trie }

fn trie_key_bytes(key: &str) -> *mut u8:
    unsafe { **(&key as *const *const *mut u8) }

impl[V] Trie[V]:
    pub fn len() -> i64: unsafe { trie_num_entries(self.trie) } as i64
    pub fn is_empty() -> bool: self.len() == 0

    fn lookup(key: &str) -> *mut Slot[V]:
        unsafe { trie_lookup_binary(self.trie, trie_key_bytes(key), key.len() as c_int) } as *mut Slot[V]

    /// Stores `value` under `key`; returns the previous value, if any.
    pub mut fn insert(key: &str, value: V) -> Option[V]:
        var previous = self.lookup(key)
        let slot = unsafe { with_alloc(sizeof[Slot[V]]() as i64) } as *mut Slot[V]
        unsafe { *slot = Slot { compare: slot_unordered, value: value } }
        assert(unsafe { trie_insert_binary(self.trie, trie_key_bytes(key), key.len() as c_int, slot as *mut c_void) } != 0)
        if previous as i64 == 0: return None
        let old: V = unsafe { move previous.value }
        unsafe { with_free(previous as *mut u8) }
        Some(old)

    /// Observes the value under `key`.
    pub fn get(key: &str) -> Option[&V]:
        let slot = self.lookup(key)
        if slot as i64 == 0: return None
        Some(unsafe { &(*slot).value })

    pub fn contains(key: &str) -> bool: self.lookup(key) as i64 != 0

    /// Transfers the value under `key` out.
    pub mut fn remove(key: &str) -> Option[V]:
        var slot = self.lookup(key)
        if slot as i64 == 0: return None
        assert(unsafe { trie_remove_binary(self.trie, trie_key_bytes(key), key.len() as c_int) } != 0)
        let value: V = unsafe { move slot.value }
        unsafe { with_free(slot as *mut u8) }
        Some(value)

    /// The node at the end of `prefix`, or null when no key starts with it.
    fn prefix_node(prefix: &str) -> *mut _TrieNode:
        var node = unsafe { (*self.trie).root_node }
        let bytes = trie_key_bytes(prefix)
        var i: i64 = 0
        while node as i64 != 0 and i < prefix.len():
            node = unsafe { (*node).next[bytes[i] as i32] }
            i = i + 1
        node

    /// Values of every key that starts with `prefix`, in byte order of the
    /// keys (an empty prefix visits the whole trie).
    pub fn iter_prefix(prefix: &str) -> TrieValues[V]:
        var values: TrieValues[V] = TrieValues { nodes: Vec.new(), children: Vec.new() }
        let start = self.prefix_node(prefix)
        if start as i64 != 0:
            values.nodes.push(start as i64)
            values.children.push(-1)
        values

    pub fn iter() -> TrieValues[V]: self.iter_prefix("")

    unsafe fn drop_subtree(node: *mut _TrieNode) -> Unit:
        if node as i64 == 0: return
        var slot = unsafe { (*node).data } as *mut Slot[V]
        if slot as i64 != 0:
            let value: V = unsafe { move slot.value }
            drop(value)
            unsafe { with_free(slot as *mut u8) }
        for child in 0..256:
            unsafe { self.drop_subtree((*node).next[child]) }

impl[V] Drop for Trie[V]:
    move fn drop():
        unsafe { self.drop_subtree((*self.trie).root_node) }
        unsafe { trie_free(self.trie) }

/// Depth-first cursor over a trie subtree; obtain via `trie.iter_prefix(p)`.
/// `next()` yields `Some(&V)` per key in byte order, then `None`. Each
/// frame is a node and the index of the next child to visit (-1: the node
/// itself has not been yielded yet).
pub type TrieValues[V] { nodes: Vec[i64], children: Vec[i32] }

impl[V] TrieValues[V]:
    pub mut fn next() -> Option[&V]:
        while self.nodes.len() > 0:
            let top = self.nodes.len() as i32 - 1
            let node = self.nodes[top] as *mut _TrieNode
            let child: i32 = self.children[top]
            if child < 0:
                self.children[top] = 0
                let slot = unsafe { (*node).data } as *const Slot[V]
                if slot as i64 != 0: return Some(unsafe { &(*slot).value })
                continue
            if child >= 256:
                self.nodes.pop()
                self.children.pop()
                continue
            self.children[top] = child + 1
            let next = unsafe { (*node).next[child] }
            if next as i64 != 0:
                self.nodes.push(next as i64)
                self.children.push(-1)
        None
