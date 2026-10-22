// std.collections.ordered_set — OrderedSet[T]: an ordered set over the
// migrated STC `sset` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the
// facade map's primary engine, an AA-tree). The engine orders slot pointers
// through the facade's comparator (std.collections.stc_slot); the facade
// owns every value.
//
// Complexity contract: O(log n) insert, lookup and remove; in-order
// traversal O(n).

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.stc_slot_prefix
use std.collections.stc_slot.stc_slot_unhashed
use rt.rt_core

/// Values kept in ascending `Ord` order, one per equal class (D41: `cmp`
/// backs the `<` / `>` the comparator applies to views). `contains` and
/// `get` observe; `remove` transfers (D27).
pub type OrderedSet[T] { set: stc_slot_sset }

pub fn OrderedSet.new[T: Ord]() -> OrderedSet[T]:
    OrderedSet { set: stc_slot_sset_init() }

impl[T: Ord] OrderedSet[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const StcSlot[T])).value }
            let right = unsafe { &(*(b as *const StcSlot[T])).value }
            if left < right: -1 else if left > right: 1 else: 0

    pub fn len() -> isize: unsafe { stc_slot_sset_size(&raw const self.set) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    // The engine compares a probe against stored slots through the probe's
    // comparator, so a probe is a slot too: the prefix and a byte image of
    // `value` that is never read back as owned.
    unsafe fn probe(value: &T) -> *mut StcSlot[T]:
        let probe = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
        (*probe).prefix = stc_slot_prefix(self.comparator(), stc_slot_unhashed)
        with_memcpy(&raw mut (*probe).value as *mut u8, &raw const *value as *const u8, sizeof[T]() as i64)
        probe

    unsafe fn find_slot(value: &T) -> *mut StcSlot[T]:
        let probe = self.probe(value)
        let found = stc_slot_sset_get(&raw const self.set, probe as *mut stc_slot_head)
        with_free(probe as *mut u8)
        if found as i64 == 0: 0 as *mut StcSlot[T] else: (*found) as *mut StcSlot[T]

    /// Inserts `value`; returns false (and drops the value) when an equal
    /// value is already present.
    pub mut fn insert(value: T) -> bool:
        var slot = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
        unsafe { *slot = StcSlot { prefix: stc_slot_prefix(self.comparator(), stc_slot_unhashed), value: value } }
        let result = unsafe { stc_slot_sset_insert(&raw mut self.set, slot as *mut stc_slot_head) }
        if result.inserted: return true
        let rejected: T = unsafe { move slot.value }
        drop(rejected)
        with_free(slot as *mut u8)
        false

    pub fn contains(value: &T) -> bool: unsafe { self.find_slot(value) } as i64 != 0

    /// Observes the stored value equal to `value`, if any.
    pub fn get(value: &T) -> Option[&T]:
        let slot = unsafe { self.find_slot(value) }
        if slot as i64 == 0: None else: Some(unsafe { &(*slot).value })

    /// Transfers the value equal to `value` out, if any.
    pub mut fn remove(value: &T) -> Option[T]:
        var slot = unsafe { self.find_slot(value) }
        if slot as i64 == 0: return None
        let probe = unsafe { self.probe(value) }
        assert(unsafe { stc_slot_sset_erase(&raw mut self.set, probe as *mut stc_slot_head) } != 0)
        with_free(probe as *mut u8)
        let taken: T = unsafe { move slot.value }
        with_free(slot as *mut u8)
        Some(taken)

    /// Observes the least value, or `None` when empty.
    pub fn first() -> Option[&T]:
        if self.len() == 0: return None
        let slot = unsafe { *stc_slot_sset_front(&raw const self.set) } as *const StcSlot[T]
        Some(unsafe { &(*slot).value })

    /// Observes the greatest value, or `None` when empty.
    pub fn last() -> Option[&T]:
        if self.len() == 0: return None
        let slot = unsafe { *stc_slot_sset_back(&raw const self.set) } as *const StcSlot[T]
        Some(unsafe { &(*slot).value })

    /// Drops every value and empties the set.
    pub mut fn clear():
        var cursor = unsafe { stc_slot_sset_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            var slot = unsafe { *cursor.ref } as *mut StcSlot[T]
            let value: T = unsafe { move slot.value }
            drop(value)
            with_free(slot as *mut u8)
            unsafe { stc_slot_sset_next(&raw mut cursor) }
        unsafe { stc_slot_sset_clear(&raw mut self.set) }

    /// In-order views of the values (D44: traversal observes).
    pub fn iter() -> OrderedSetIter[T]:
        OrderedSetIter { cursor: unsafe { stc_slot_sset_begin(&raw const self.set) } }

impl[T] Drop for OrderedSet[T]:
    move fn drop():
        var cursor = unsafe { stc_slot_sset_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            var slot = unsafe { *cursor.ref } as *mut StcSlot[T]
            let value: T = unsafe { move slot.value }
            drop(value)
            with_free(slot as *mut u8)
            unsafe { stc_slot_sset_next(&raw mut cursor) }
        unsafe { stc_slot_sset_drop(&raw const self.set) }

pub type OrderedSetIter[T] ephemeral { cursor: stc_slot_sset_iter }

impl[T] OrderedSetIter[T]:
    pub mut fn next() -> Option[&T]:
        if self.cursor.ref as i64 == 0: return None
        let slot = unsafe { *self.cursor.ref } as *const StcSlot[T]
        unsafe { stc_slot_sset_next(&raw mut self.cursor) }
        Some(unsafe { &(*slot).value })

