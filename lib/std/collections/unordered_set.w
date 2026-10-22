// std.collections.unordered_set — UnorderedSet[T]: a hash set in no stated
// order over the migrated STC `hset` (docs/proposals/stdlib_sourcing_plan.md,
// Phase 3; D149: `HashSet` keeps rt_core's insertion-ordered layout, this
// is the unordered one for hot paths that need no order, the way Zig
// ships both). The engine (Robin Hood hashing) holds slot pointers
// (std.collections.stc_slot); the facade owns every value. Keys hash
// through `std.hash.hash_of` and compare through `==` (D96).
//
// Complexity contract: O(1) expected insert, lookup and remove; a removal
// allocates nothing.

use std.hash
use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.stc_slot_prefix
use rt.rt_core

/// `contains` and `get` observe; `insert` owns its input and refuses an
/// equal value; `remove` transfers (D27). Traversal observes, in no order.
pub type UnorderedSet[T] { set: stc_slot_set }

pub fn UnorderedSet.new[T: Key]() -> UnorderedSet[T]:
    UnorderedSet { set: stc_slot_set_init() }

impl[T: Key] UnorderedSet[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const StcSlot[T])).value }
            let right = unsafe { &(*(b as *const StcSlot[T])).value }
            if left == right: 0 else: 1

    fn hasher() -> fn(*const u8) -> u64:
        p => hash_of(unsafe { &(*(p as *const StcSlot[T])).value })

    pub fn len() -> isize: unsafe { stc_slot_set_size(&raw const self.set) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    // The engine hashes and compares a probe through the probe's own
    // callbacks, so a probe is a slot too: the prefix and a byte image of
    // `value` that is never read back as owned.
    unsafe fn probe(value: &T) -> *mut StcSlot[T]:
        let probe = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
        (*probe).prefix = stc_slot_prefix(self.comparator(), self.hasher())
        with_memcpy(&raw mut (*probe).value as *mut u8, &raw const *value as *const u8, sizeof[T]() as i64)
        probe

    unsafe fn find_slot(value: &T) -> *mut StcSlot[T]:
        let probe = self.probe(value)
        let found = stc_slot_set_get(&raw const self.set, probe as *mut stc_slot_head)
        with_free(probe as *mut u8)
        if found as i64 == 0: 0 as *mut StcSlot[T] else: (*found) as *mut StcSlot[T]

    /// Inserts `value`; returns false (and drops the value) when an equal
    /// value is already present.
    pub mut fn insert(value: T) -> bool:
        var slot = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
        unsafe { *slot = StcSlot { prefix: stc_slot_prefix(self.comparator(), self.hasher()), value: value } }
        let result = unsafe { stc_slot_set_insert(&raw mut self.set, slot as *mut stc_slot_head) }
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
        assert(unsafe { stc_slot_set_erase(&raw mut self.set, probe as *mut stc_slot_head) } != 0)
        with_free(probe as *mut u8)
        let taken: T = unsafe { move slot.value }
        with_free(slot as *mut u8)
        Some(taken)

    /// Drops every value and empties the set.
    pub mut fn clear():
        var cursor = unsafe { stc_slot_set_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            var slot = unsafe { *cursor.ref } as *mut StcSlot[T]
            let value: T = unsafe { move slot.value }
            drop(value)
            with_free(slot as *mut u8)
            unsafe { stc_slot_set_next(&raw mut cursor) }
        unsafe { stc_slot_set_clear(&raw mut self.set) }

    /// Views of the values, in no stated order (D44: traversal observes).
    pub fn iter() -> UnorderedSetIter[T]:
        UnorderedSetIter { cursor: unsafe { stc_slot_set_begin(&raw const self.set) } }

impl[T] Drop for UnorderedSet[T]:
    move fn drop():
        var cursor = unsafe { stc_slot_set_begin(&raw const self.set) }
        while cursor.ref as i64 != 0:
            var slot = unsafe { *cursor.ref } as *mut StcSlot[T]
            let value: T = unsafe { move slot.value }
            drop(value)
            with_free(slot as *mut u8)
            unsafe { stc_slot_set_next(&raw mut cursor) }
        unsafe { stc_slot_set_drop(&raw const self.set) }

pub type UnorderedSetIter[T] ephemeral { cursor: stc_slot_set_iter }

impl[T] UnorderedSetIter[T]:
    pub mut fn next() -> Option[&T]:
        if self.cursor.ref as i64 == 0: return None
        let slot = unsafe { *self.cursor.ref } as *const StcSlot[T]
        unsafe { stc_slot_set_next(&raw mut self.cursor) }
        Some(unsafe { &(*slot).value })
