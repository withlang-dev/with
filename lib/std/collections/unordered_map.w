// std.collections.unordered_map — UnorderedMap[K, V]: a hash map in no
// stated order over the migrated STC `hset` (docs/proposals/stdlib_sourcing_plan.md,
// Phase 3; D149: `HashMap` keeps rt_core's insertion-ordered layout, this
// is the unordered one for hot paths that need no order, the way Zig
// ships both). Each entry is one facade-owned slot holding the key and
// the value; the engine (Robin Hood hashing) holds slot pointers and
// hashes and compares keys through the facade's callbacks
// (std.collections.stc_slot). Keys hash through `std.hash.hash_of` and
// compare through `==` (D96).
//
// Complexity contract: O(1) expected insert, lookup and remove; a removal
// allocates nothing.

use std.hash
use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.StcSlotPrefix
use std.collections.stc_slot.stc_slot_prefix
use rt.rt_core

/// One entry: the slot prefix, the key, the value. A probe for a lookup is a
/// `StcSlot[K]` — the same prefix and the key at the same offset — so the
/// engine hashes and compares it like a stored entry without a value.
pub type UnorderedEntry[K, V] { prefix: StcSlotPrefix, key: K, value: V }

/// `get` observes, `insert` owns its inputs and returns the value it
/// replaced, `remove` transfers (D27). Traversal observes, in no order.
pub type UnorderedMap[K, V] { set: stc_slot_set }

pub fn UnorderedMap.new[K: Key, V]() -> UnorderedMap[K, V]:
    UnorderedMap { set: stc_slot_set_init() }

impl[K: Key, V] UnorderedMap[K, V]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const StcSlot[K])).value }
            let right = unsafe { &(*(b as *const StcSlot[K])).value }
            if left == right: 0 else: 1

    fn hasher() -> fn(*const u8) -> u64:
        p => hash_of(unsafe { &(*(p as *const StcSlot[K])).value })

    pub fn len() -> isize: unsafe { stc_slot_set_size(&raw const self.set) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    unsafe fn probe(key: &K) -> *mut StcSlot[K]:
        let probe = with_alloc(sizeof[StcSlot[K]]() as i64) as *mut StcSlot[K]
        (*probe).prefix = stc_slot_prefix(self.comparator(), self.hasher())
        with_memcpy(&raw mut (*probe).value as *mut u8, &raw const *key as *const u8, sizeof[K]() as i64)
        probe

    unsafe fn find_entry(key: &K) -> *mut UnorderedEntry[K, V]:
        let probe = self.probe(key)
        let found = stc_slot_set_get(&raw const self.set, probe as *mut stc_slot_head)
        with_free(probe as *mut u8)
        if found as i64 == 0: 0 as *mut UnorderedEntry[K, V] else: (*found) as *mut UnorderedEntry[K, V]

    /// Stores `value` under `key`; returns the previous value, if any (the
    /// stored key is kept, the new one dropped).
    pub mut fn insert(key: K, value: V) -> Option[V]:
        let entry = with_alloc(sizeof[UnorderedEntry[K, V]]() as i64) as *mut UnorderedEntry[K, V]
        unsafe { *entry = UnorderedEntry { prefix: stc_slot_prefix(self.comparator(), self.hasher()), key: key, value: value } }
        let result = unsafe { stc_slot_set_insert(&raw mut self.set, entry as *mut stc_slot_head) }
        if result.inserted: return None
        // An equal key is stored: the table's pointer is repointed at the new
        // entry (same key, same hash) and the old entry transfers its value
        // out and drops its key.
        var old = unsafe { *result.ref } as *mut UnorderedEntry[K, V]
        unsafe { *result.ref = entry as *mut stc_slot_head }
        let stored_key: K = unsafe { move old.key }
        drop(stored_key)
        let previous: V = unsafe { move old.value }
        with_free(old as *mut u8)
        Some(previous)

    pub fn contains(key: &K) -> bool: unsafe { self.find_entry(key) } as i64 != 0

    /// Observes the value under `key`, if any (D22).
    pub fn get(key: &K) -> Option[&V]:
        let entry = unsafe { self.find_entry(key) }
        if entry as i64 == 0: None else: Some(unsafe { &(*entry).value })

    /// Transfers the value under `key` out, if any; the key drops.
    pub mut fn remove(key: &K) -> Option[V]:
        var entry = unsafe { self.find_entry(key) }
        if entry as i64 == 0: return None
        let probe = unsafe { self.probe(key) }
        assert(unsafe { stc_slot_set_erase(&raw mut self.set, probe as *mut stc_slot_head) } != 0)
        with_free(probe as *mut u8)
        let stored_key: K = unsafe { move entry.key }
        drop(stored_key)
        let value: V = unsafe { move entry.value }
        with_free(entry as *mut u8)
        Some(value)

    /// Views of the entries, in no stated order (D44: traversal observes).
    pub fn iter() -> UnorderedMapIter[K, V]:
        UnorderedMapIter { cursor: unsafe { stc_slot_set_begin(&raw const self.set) } }

impl[K, V] Drop for UnorderedMap[K, V]:
    move fn drop():
        var cursor = unsafe { stc_slot_set_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            var entry = unsafe { *cursor.ref } as *mut UnorderedEntry[K, V]
            let key: K = unsafe { move entry.key }
            drop(key)
            let value: V = unsafe { move entry.value }
            drop(value)
            with_free(entry as *mut u8)
            unsafe { stc_slot_set_next(&raw mut cursor) }
        unsafe { stc_slot_set_drop(&raw const self.set) }

pub type UnorderedMapIter[K, V] ephemeral { cursor: stc_slot_set_iter }

impl[K, V] UnorderedMapIter[K, V]:
    pub mut fn next() -> Option[(&K, &V)]:
        if self.cursor.ref as i64 == 0: return None
        let entry = unsafe { *self.cursor.ref } as *const UnorderedEntry[K, V]
        unsafe { stc_slot_set_next(&raw mut self.cursor) }
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))
