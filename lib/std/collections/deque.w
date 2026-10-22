// std.collections.deque — Deque[T]: a double-ended queue over the migrated
// STC `deque` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the facade
// map's primary engine, a ring buffer). The engine holds slot pointers
// (std.collections.stc_slot); the facade owns every value.
//
// Complexity contract: O(1) amortized push and pop at either end, O(1)
// indexed access.

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.stc_slot_prefix
use std.collections.stc_slot.stc_slot_unhashed
use std.collections.stc_slot.stc_slot_unordered
use rt.rt_core

/// `front`/`back`/`d[i]` observe, `pop_front`/`pop_back` transfer (D27);
/// an out-of-range index panics (§15.11: absence is a bug, not a value).
pub type Deque[T] { deque: stc_slot_deque }

pub fn Deque.new[T]() -> Deque[T]:
    Deque { deque: stc_slot_deque_init() }

impl[T] Deque[T]:
    pub fn len() -> isize: unsafe { stc_slot_deque_size(&raw const self.deque) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    unsafe fn new_slot(value: T) -> *mut StcSlot[T]:
        let slot = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
        *slot = StcSlot { prefix: stc_slot_prefix(stc_slot_unordered, stc_slot_unhashed), value: value }
        slot

    pub mut fn push_back(value: T):
        let slot = unsafe { self.new_slot(value) }
        unsafe { stc_slot_deque_push_back(&raw mut self.deque, slot as *mut stc_slot_head) }

    pub mut fn push_front(value: T):
        let slot = unsafe { self.new_slot(value) }
        unsafe { stc_slot_deque_push_front(&raw mut self.deque, slot as *mut stc_slot_head) }

    unsafe fn take(slot: *mut StcSlot[T]) -> T:
        var owned = slot
        let value: T = move owned.value
        with_free(slot as *mut u8)
        value

    /// Transfers the last value out, or `None` when empty.
    pub mut fn pop_back() -> Option[T]:
        if self.len() == 0: return None
        let slot = unsafe { *stc_slot_deque_back(&raw const self.deque) } as *mut StcSlot[T]
        unsafe { stc_slot_deque_pop_back(&raw mut self.deque) }
        Some(unsafe { self.take(slot) })

    /// Transfers the first value out, or `None` when empty.
    pub mut fn pop_front() -> Option[T]:
        if self.len() == 0: return None
        let slot = unsafe { *stc_slot_deque_front(&raw const self.deque) } as *mut StcSlot[T]
        unsafe { stc_slot_deque_pop_front(&raw mut self.deque) }
        Some(unsafe { self.take(slot) })

    pub fn front() -> Option[&T]:
        if self.len() == 0: return None
        let slot = unsafe { *stc_slot_deque_front(&raw const self.deque) } as *const StcSlot[T]
        Some(unsafe { &(*slot).value })

    pub fn back() -> Option[&T]:
        if self.len() == 0: return None
        let slot = unsafe { *stc_slot_deque_back(&raw const self.deque) } as *const StcSlot[T]
        Some(unsafe { &(*slot).value })

    /// Drops every value and empties the deque.
    pub mut fn clear():
        while self.len() > 0:
            let value = self.pop_back().unwrap()
            drop(value)

    /// Views of the values, front to back (D44: traversal observes).
    pub fn iter() -> DequeIter[T]:
        DequeIter { deque: (&raw const self.deque) as i64, index: 0, len: self.len() }

    /// Observes the value at `index`; panics out of range (D27). `d[i]` is
    /// the spelling once a generic type can implement IndexPlace (#2560).
    pub fn get(index: isize) -> &T:
        assert(index >= 0 and index < self.len(), "Deque index out of bounds")
        let slot = unsafe { *stc_slot_deque_at(&raw const self.deque, index as c_long) } as *const StcSlot[T]
        unsafe { &(*slot).value }

impl[T] Drop for Deque[T]:
    move fn drop():
        let count = self.len()
        for index in 0..count:
            let slot = unsafe { *stc_slot_deque_at(&raw const self.deque, index as c_long) } as *mut StcSlot[T]
            var owned = slot
            let value: T = unsafe { move owned.value }
            drop(value)
            with_free(slot as *mut u8)
        unsafe { stc_slot_deque_drop(&raw const self.deque) }

pub type DequeIter[T] ephemeral { deque: i64, index: isize, len: isize }

impl[T] DequeIter[T]:
    pub mut fn next() -> Option[&T]:
        if self.index >= self.len: return None
        let slot = unsafe { *stc_slot_deque_at(self.deque as *const stc_slot_deque, self.index as c_long) } as *const StcSlot[T]
        self.index = self.index + 1
        Some(unsafe { &(*slot).value })

