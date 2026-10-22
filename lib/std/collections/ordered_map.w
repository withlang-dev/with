// std.collections.ordered_map — OrderedMap[K, V]: an ordered map over the
// migrated STC `sset` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the
// facade map's primary ordered engine, an AA-tree). Each entry is one
// facade-owned slot holding the key and the value; the engine orders slot
// pointers through the facade's key comparator (std.collections.stc_slot).
//
// Complexity contract: O(log n) insert, lookup and remove; in-order
// traversal O(n).

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.StcSlotPrefix
use std.collections.stc_slot.stc_slot_prefix
use std.collections.stc_slot.stc_slot_unhashed
use rt.rt_core

/// One entry: the slot prefix, the key, the value. A probe for a lookup is a
/// `StcSlot[K]` — the same prefix and the key at the same offset — so the
/// engine compares it like a stored entry without a value.
pub type OrderedEntry[K, V] { prefix: StcSlotPrefix, key: K, value: V }

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

    pub fn len() -> isize: unsafe { stc_slot_sset_size(&raw const self.set) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    unsafe fn probe(key: &K) -> *mut StcSlot[K]:
        let probe = with_alloc(sizeof[StcSlot[K]]() as i64) as *mut StcSlot[K]
        (*probe).prefix = stc_slot_prefix(self.comparator(), stc_slot_unhashed)
        with_memcpy(&raw mut (*probe).value as *mut u8, &raw const *key as *const u8, sizeof[K]() as i64)
        probe

    unsafe fn find_entry(key: &K) -> *mut OrderedEntry[K, V]:
        let probe = self.probe(key)
        let found = stc_slot_sset_get(&raw const self.set, probe as *mut stc_slot_head)
        with_free(probe as *mut u8)
        if found as i64 == 0: 0 as *mut OrderedEntry[K, V] else: (*found) as *mut OrderedEntry[K, V]

    /// Stores `value` under `key`; returns the previous value, if any (the
    /// stored key is kept, the new one dropped).
    pub mut fn insert(key: K, value: V) -> Option[V]:
        let entry = with_alloc(sizeof[OrderedEntry[K, V]]() as i64) as *mut OrderedEntry[K, V]
        unsafe { *entry = OrderedEntry { prefix: stc_slot_prefix(self.comparator(), stc_slot_unhashed), key: key, value: value } }
        let result = unsafe { stc_slot_sset_insert(&raw mut self.set, entry as *mut stc_slot_head) }
        if result.inserted: return None
        // An equal key is stored: the node's pointer is repointed at the new
        // entry (the order is unchanged) and the old entry transfers its
        // value out and drops its key.
        var old = unsafe { *result.ref } as *mut OrderedEntry[K, V]
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
        assert(unsafe { stc_slot_sset_erase(&raw mut self.set, probe as *mut stc_slot_head) } != 0)
        with_free(probe as *mut u8)
        let stored_key: K = unsafe { move entry.key }
        drop(stored_key)
        let value: V = unsafe { move entry.value }
        with_free(entry as *mut u8)
        Some(value)

    /// Observes the least key's entry, or `None` when empty.
    pub fn first() -> Option[(&K, &V)]:
        if self.len() == 0: return None
        let entry = unsafe { *stc_slot_sset_front(&raw const self.set) } as *const OrderedEntry[K, V]
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))

    /// Observes the greatest key's entry, or `None` when empty.
    pub fn last() -> Option[(&K, &V)]:
        if self.len() == 0: return None
        let entry = unsafe { *stc_slot_sset_back(&raw const self.set) } as *const OrderedEntry[K, V]
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))

    /// In-order views of the entries (D44: traversal observes).
    pub fn iter() -> OrderedMapIter[K, V]:
        OrderedMapIter { cursor: unsafe { stc_slot_sset_begin(&raw const self.set) } }

impl[K, V] Drop for OrderedMap[K, V]:
    move fn drop():
        var cursor = unsafe { stc_slot_sset_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            var entry = unsafe { *cursor.ref } as *mut OrderedEntry[K, V]
            let key: K = unsafe { move entry.key }
            drop(key)
            let value: V = unsafe { move entry.value }
            drop(value)
            with_free(entry as *mut u8)
            unsafe { stc_slot_sset_next(&raw mut cursor) }
        unsafe { stc_slot_sset_drop(&raw const self.set) }

pub type OrderedMapIter[K, V] ephemeral { cursor: stc_slot_sset_iter }

impl[K, V] OrderedMapIter[K, V]:
    pub mut fn next() -> Option[(&K, &V)]:
        if self.cursor.ref as i64 == 0: return None
        let entry = unsafe { *self.cursor.ref } as *const OrderedEntry[K, V]
        unsafe { stc_slot_sset_next(&raw mut self.cursor) }
        Some((unsafe { &(*entry).key }, unsafe { &(*entry).value }))


