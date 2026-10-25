// std.collections.ordered_map — OrderedMap[K, V]: an ordered map over the
// migrated STC `sset` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the
// facade map's primary ordered engine, an AA-tree). Each entry is one
// facade-owned slot holding the key and the value (std.collections.stc_slot's
// `StcEntry`); the engine orders entry pointers through the facade's key
// comparator.
//
// Complexity contract: O(log n) insert, lookup and remove; in-order
// traversal O(n).

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
use std.collections.stc_slot.stc_slot_unhashed
use rt.rt_core

/// Keys kept in ascending `Ord` order (D41). `get` observes, `insert` owns
/// its inputs and returns the value it replaced, `remove` transfers (D27).
pub type OrderedMap[K, V] { set: stc_slot_sset }

pub fn OrderedMap.new[K: Ord, V]() -> OrderedMap[K, V]:
    OrderedMap { set: stc_slot_sset_init() }

impl[K: Ord, V] OrderedMap[K, V]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const StcSlot[K])).value }
            let right = unsafe { &(*(b as *const StcSlot[K])).value }
            if left < right: -1 else if left > right: 1 else: 0

    pub fn len() -> isize: self.set.size() as isize
    pub fn is_empty() -> bool: self.len() == 0

    fn find_entry(key: &K) -> *mut StcEntry[K, V]:
        let probe = stc_slot_probe(key, self.comparator(), stc_slot_unhashed)
        let found = unsafe { stc_slot_sset_get(&raw const self.set, probe) }
        stc_slot_discard_probe(probe)
        if found as i64 == 0: null else: unsafe { *found } as *mut StcEntry[K, V]

    /// Stores `value` under `key`; returns the previous value, if any (the
    /// stored key is kept, the new one dropped).
    pub mut fn insert(key: K, value: V) -> Option[V]:
        let entry = stc_entry_new(key, value, self.comparator(), stc_slot_unhashed)
        let result = unsafe { stc_slot_sset_insert(&raw mut self.set, entry) }
        if result.inserted: return None
        // An equal key is stored: the node's pointer is repointed at the new
        // entry (the order is unchanged) and the old entry transfers its
        // value out and drops its key.
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
        let probe = stc_slot_probe(key, self.comparator(), stc_slot_unhashed)
        assert(unsafe { stc_slot_sset_erase(&raw mut self.set, probe) } != 0)
        stc_slot_discard_probe(probe)
        Some(unsafe { stc_entry_take(entry) })

    /// Observes the least key's entry, or `None` when empty.
    pub fn first() -> Option[(&K, &V)] from self:
        if self.len() == 0: return None
        let entry = unsafe { *stc_slot_sset_front(&raw const self.set) } as *const StcEntry[K, V]
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))

    /// Observes the greatest key's entry, or `None` when empty.
    pub fn last() -> Option[(&K, &V)] from self:
        if self.len() == 0: return None
        let entry = unsafe { *stc_slot_sset_back(&raw const self.set) } as *const StcEntry[K, V]
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))

    /// In-order views of the entries (D44: traversal observes).
    pub fn iter() -> OrderedMapIter[K, V]:
        OrderedMapIter { cursor: self.set.begin() }

impl[K, V] Drop for OrderedMap[K, V]:
    move fn drop():
        var cursor = self.set.begin()
        while cursor.ref as i64 != 0:
            unsafe { stc_entry_release(unsafe { *cursor.ref } as *mut StcEntry[K, V]) }
            cursor.next()
        unsafe { stc_slot_sset_drop(&raw const self.set) }

pub type OrderedMapIter[K, V] ephemeral { cursor: stc_slot_sset_iter }

impl[K, V] OrderedMapIter[K, V]:
    pub mut fn next() -> Option[(&K, &V)]:
        if self.cursor.ref as i64 == 0: return None
        let entry = unsafe { *self.cursor.ref } as *const StcEntry[K, V]
        self.cursor.next()
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))
