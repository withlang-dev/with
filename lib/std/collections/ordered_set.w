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
use std.collections.stc_slot.stc_slot_new
use std.collections.stc_slot.stc_slot_view
use std.collections.stc_slot.stc_slot_take
use std.collections.stc_slot.stc_slot_release
use std.collections.stc_slot.stc_slot_probe
use std.collections.stc_slot.stc_slot_discard_probe
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

    fn find_slot(value: &T) -> *mut StcSlot[T]:
        let probe = stc_slot_probe(value, self.comparator(), stc_slot_unhashed)
        let found = unsafe { stc_slot_sset_get(&raw const self.set, probe) }
        stc_slot_discard_probe(probe)
        if found as i64 == 0: null else: unsafe { *found } as *mut StcSlot[T]

    /// Inserts `value`; returns false (and drops the value) when an equal
    /// value is already present.
    pub mut fn insert(value: T) -> bool:
        let slot = stc_slot_new(value, self.comparator(), stc_slot_unhashed)
        let result = unsafe { stc_slot_sset_insert(&raw mut self.set, slot) }
        if result.inserted: return true
        unsafe { stc_slot_release(slot as *mut StcSlot[T]) }
        false

    pub fn contains(value: &T) -> bool: self.find_slot(value) as i64 != 0

    /// Observes the stored value equal to `value`, if any.
    pub fn get(value: &T) -> Option[&T] from self:
        let slot = self.find_slot(value)
        if slot as i64 == 0: None else: Some(unsafe { &(*slot).value })

    /// Transfers the value equal to `value` out, if any.
    pub mut fn remove(value: &T) -> Option[T]:
        let slot = self.find_slot(value)
        if slot as i64 == 0: return None
        let probe = stc_slot_probe(value, self.comparator(), stc_slot_unhashed)
        assert(unsafe { stc_slot_sset_erase(&raw mut self.set, probe) } != 0)
        stc_slot_discard_probe(probe)
        Some(unsafe { stc_slot_take(slot) })

    /// Observes the least value, or `None` when empty.
    pub fn first() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &(*(*stc_slot_sset_front(&raw const self.set) as *const StcSlot[T])).value })

    /// Observes the greatest value, or `None` when empty.
    pub fn last() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &(*(*stc_slot_sset_back(&raw const self.set) as *const StcSlot[T])).value })

    /// Drops every value and empties the set.
    pub mut fn clear():
        var cursor = unsafe { stc_slot_sset_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            unsafe { stc_slot_release(unsafe { *cursor.ref } as *mut StcSlot[T]) }
            unsafe { stc_slot_sset_next(&raw mut cursor) }
        unsafe { stc_slot_sset_clear(&raw mut self.set) }

    /// In-order views of the values (D44: traversal observes).
    pub fn iter() -> OrderedSetIter[T]:
        OrderedSetIter { cursor: unsafe { stc_slot_sset_begin(&raw const self.set) } }

impl[T] Drop for OrderedSet[T]:
    move fn drop():
        var cursor = unsafe { stc_slot_sset_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            unsafe { stc_slot_release(unsafe { *cursor.ref } as *mut StcSlot[T]) }
            unsafe { stc_slot_sset_next(&raw mut cursor) }
        unsafe { stc_slot_sset_drop(&raw const self.set) }

pub type OrderedSetIter[T] ephemeral { cursor: stc_slot_sset_iter }

impl[T] OrderedSetIter[T]:
    pub mut fn next() -> Option[&T]:
        if self.cursor.ref as i64 == 0: return None
        let slot = unsafe { *self.cursor.ref } as *const StcSlot[T]
        unsafe { stc_slot_sset_next(&raw mut self.cursor) }
        Some(unsafe { stc_slot_view(slot) })
