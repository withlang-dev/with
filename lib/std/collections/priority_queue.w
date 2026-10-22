// std.collections.priority_queue — PriorityQueue[T]: an owning heap over the
// migrated STC `pqueue` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the
// facade map's primary engine). The engine orders slot pointers through the
// facade's comparator (std.collections.stc_slot); the facade owns every value.
//
// Complexity contract: O(log n) push and pop, O(1) peek.

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.stc_slot_prefix
use std.collections.stc_slot.stc_slot_unhashed
use rt.rt_core

/// A max-queue by default (`pop` yields the greatest value); `new_min()`
/// builds the min-queue. `T: Ord` orders through `cmp` (D41). `peek`
/// observes, `pop` transfers (D27).
pub type PriorityQueue[T] { queue: stc_slot_pqueue, descending: bool }

pub fn PriorityQueue.new[T: Ord]() -> PriorityQueue[T]:
    PriorityQueue { queue: stc_slot_pqueue_init(), descending: false }

pub fn PriorityQueue.new_min[T: Ord]() -> PriorityQueue[T]:
    PriorityQueue { queue: stc_slot_pqueue_init(), descending: true }

impl[T: Ord] PriorityQueue[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        if self.descending:
            (a, b) =>
                let left = unsafe { &(*(a as *const StcSlot[T])).value }
                let right = unsafe { &(*(b as *const StcSlot[T])).value }
                if left < right: 1 else if left > right: -1 else: 0
        else:
            (a, b) =>
                let left = unsafe { &(*(a as *const StcSlot[T])).value }
                let right = unsafe { &(*(b as *const StcSlot[T])).value }
                if left < right: -1 else if left > right: 1 else: 0

    pub fn len() -> isize: unsafe { stc_slot_pqueue_size(&raw const self.queue) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    pub mut fn push(value: T):
        let slot = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
        unsafe { *slot = StcSlot { prefix: stc_slot_prefix(self.comparator(), stc_slot_unhashed), value: value } }
        unsafe { stc_slot_pqueue_push(&raw mut self.queue, slot as *mut stc_slot_head) }

    /// Transfers the top value out, or `None` when empty.
    pub mut fn pop() -> Option[T]:
        if self.len() == 0: return None
        var slot = unsafe { *stc_slot_pqueue_top(&raw const self.queue) } as *mut StcSlot[T]
        unsafe { stc_slot_pqueue_pop(&raw mut self.queue) }
        let value: T = unsafe { move slot.value }
        with_free(slot as *mut u8)
        Some(value)

    /// Observes the top value, or `None` when empty.
    pub fn peek() -> Option[&T]:
        if self.len() == 0: return None
        let slot = unsafe { *stc_slot_pqueue_top(&raw const self.queue) } as *const StcSlot[T]
        Some(unsafe { &(*slot).value })

impl[T] Drop for PriorityQueue[T]:
    move fn drop():
        // The engine's pointer array is its own; walk it and release every
        // slot before the engine frees the array.
        let count = self.queue.size as i32
        for index in 0..count:
            var slot = unsafe { self.queue.data[index] } as *mut StcSlot[T]
            let value: T = unsafe { move slot.value }
            drop(value)
            with_free(slot as *mut u8)
        unsafe { stc_slot_pqueue_drop(&raw const self.queue) }
