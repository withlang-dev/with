// std.collections.unordered_map — UnorderedMap[K, V]: a hash map in no
// stated order over the migrated STC `hset` (docs/completed/stdlib_sourcing_plan.md,
// Phase 3; D149: `HashMap` keeps rt_core's insertion-ordered layout, this
// is the unordered one for hot paths that need no order, the way Zig
// ships both). Each entry is one facade-owned slot holding the key and
// the value (std.collections.stc_slot's `StcEntry`); the engine (Robin
// Hood hashing) holds entry pointers and hashes and compares keys through
// the facade's callbacks. Keys hash through `std.hash.hash_of` and compare
// through `==` (D96).
//
// Complexity contract: O(1) expected insert, lookup and remove; a removal
// allocates nothing.

use std.hash
use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.StcEntry
use std.collections.stc_slot.stc_entry_new
use std.collections.stc_slot.stc_entry_key
use std.collections.stc_slot.stc_entry_value
use std.collections.stc_slot.stc_entry_take
use std.collections.stc_slot.stc_entry_release
use std.collections.stc_slot.stc_slot_probe
use std.collections.stc_slot.stc_slot_discard_probe
use rt.rt_core

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

    pub fn len() -> isize: self.set.size() as isize
    pub fn is_empty() -> bool: self.len() == 0

    fn find_entry(key: &K) -> *mut StcEntry[K, V]:
        let probe = stc_slot_probe(key, self.comparator(), self.hasher())
        let found = unsafe { stc_slot_set_get(&raw const self.set, probe) }
        stc_slot_discard_probe(probe)
        if found as i64 == 0: null else: unsafe { *found } as *mut StcEntry[K, V]

    /// Stores `value` under `key`; returns the previous value, if any (the
    /// stored key is kept, the new one dropped).
    pub mut fn insert(key: K, value: V) -> Option[V]:
        let entry = stc_entry_new(key, value, self.comparator(), self.hasher())
        let result = unsafe { stc_slot_set_insert(&raw mut self.set, entry) }
        if result.inserted: return None
        // An equal key is stored: the table's pointer is repointed at the new
        // entry (same key, same hash) and the old entry transfers its value
        // out and drops its key.
        let old = unsafe { *result.ref } as *mut StcEntry[K, V]
        unsafe { *result.ref = entry }
        Some(unsafe { stc_entry_take(old) })

    pub fn contains(key: &K) -> bool: self.find_entry(key) as i64 != 0

    /// Observes the value under `key`, if any (D22).
    pub fn get(key: &K) -> Option[&V] from self:
        let entry = self.find_entry(key)
        if entry as i64 == 0: None else: Some(unsafe { &(*entry).value })

    /// Transfers the value under `key` out, if any; the key drops.
    pub mut fn remove(key: &K) -> Option[V]:
        let entry = self.find_entry(key)
        if entry as i64 == 0: return None
        let probe = stc_slot_probe(key, self.comparator(), self.hasher())
        assert(unsafe { stc_slot_set_erase(&raw mut self.set, probe) } != 0)
        stc_slot_discard_probe(probe)
        Some(unsafe { stc_entry_take(entry) })

    /// Views of the entries, in no stated order (D44: traversal observes).
    pub fn iter() -> UnorderedMapIter[K, V]:
        UnorderedMapIter { cursor: self.set.begin() }

impl[K, V] Drop for UnorderedMap[K, V]:
    move fn drop():
        var cursor = self.set.begin()
        while cursor.ref as i64 != 0:
            unsafe { stc_entry_release(unsafe { *cursor.ref } as *mut StcEntry[K, V]) }
            cursor.next()
        unsafe { stc_slot_set_drop(&raw const self.set) }

pub type UnorderedMapIter[K, V] ephemeral { cursor: stc_slot_set_iter }

impl[K, V] UnorderedMapIter[K, V]:
    pub mut fn next() -> Option[(&K, &V)]:
        if self.cursor.ref as i64 == 0: return None
        let entry = unsafe { *self.cursor.ref } as *const StcEntry[K, V]
        self.cursor.next()
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))
