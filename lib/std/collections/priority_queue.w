// std.collections.priority_queue — PriorityQueue[T]: an owning heap over the
// migrated STC `pqueue` (stdlib_sourcing_plan.md, Phase 3; the
// facade map's primary engine). Two shapes serve it (D148): a max-queue of
// an integer scalar up to 64 signed bits (i8..i64, u8..u32, isize) keeps
// the values inline in the engine's own heap (`stc_word_pqueue`, ordered
// by the engine's `<`, no allocation per element; its top is the value,
// readable in place); every other case — a min-queue, an unsigned 64-bit
// key, any other `T` — rides the slot shape (`stc_slot_pqueue` orders slot
// pointers through the facade's comparator, std.collections.stc_slot).
// Both engine handles live in the facade, the unused one empty. The facade
// owns every value.
//
// Complexity contract: O(log n) push and pop, O(1) peek.

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.stc_slot_new
use std.collections.stc_slot.stc_slot_view
use std.collections.stc_slot.stc_slot_take
use std.collections.stc_slot.stc_slot_release
use std.collections.stc_slot.stc_slot_unhashed
use std.collections.stc_word.stc_is_word
use std.collections.stc_word.stc_to_word
use std.collections.stc_word.stc_from_word
use rt.rt_core

/// A max-queue by default (`pop` yields the greatest value); `new_min()`
/// builds the min-queue. `T: Ord` orders through `cmp` (D41). `peek`
/// observes, `pop` transfers (D27).
pub type PriorityQueue[T] { queue: stc_slot_pqueue, words: stc_word_pqueue, descending: bool }

pub fn PriorityQueue.new[T: Ord]() -> PriorityQueue[T]:
    PriorityQueue { queue: stc_slot_pqueue_init(), words: stc_word_pqueue_init(), descending: false }

pub fn PriorityQueue.new_min[T: Ord]() -> PriorityQueue[T]:
    PriorityQueue { queue: stc_slot_pqueue_init(), words: stc_word_pqueue_init(), descending: true }

// The element types whose max-queue is the word shape: the engine's signed
// word holds the value's bits in the value's order.
fn pqueue_word_capable[T]() -> bool:
    comptime if T.name() == "u64" or T.name() == "usize": false
    else: stc_is_word[T]()

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

    // Whether this queue's values are in the word heap.
    fn in_words() -> bool:
        comptime if pqueue_word_capable[T](): not self.descending
        else: false

    pub fn len() -> isize:
        if self.in_words(): self.words.size() as isize
        else: self.queue.size() as isize
    pub fn is_empty() -> bool: self.len() == 0

    mut fn push_slot(value: T):
        unsafe { stc_slot_pqueue_push(&raw mut self.queue, stc_slot_new(value, self.comparator(), stc_slot_unhashed)) }

    pub mut fn push(value: T):
        comptime if pqueue_word_capable[T]():
            if self.descending:
                self.push_slot(value)
            else:
                self.words.push(stc_to_word(value) as i64)
                return
        else:
            self.push_slot(value)

    mut fn pop_slot() -> T:
        let slot = unsafe { *stc_slot_pqueue_top(&raw const self.queue) } as *mut StcSlot[T]
        self.queue.pop()
        unsafe { stc_slot_take(slot) }

    /// Transfers the top value out, or `None` when empty.
    pub mut fn pop() -> Option[T]:
        if self.len() == 0: return None
        comptime if pqueue_word_capable[T]():
            if self.descending: return Some(self.pop_slot())
            let word = unsafe { *stc_word_pqueue_top(&raw const self.words) }
            self.words.pop()
            Some(stc_from_word(word as u64))
        else:
            Some(self.pop_slot())

    // The top value's place in whichever heap holds it (D22: a word element
    // is read where it sits, the engine's own storage).
    unsafe fn top_place() -> *const T:
        if self.in_words(): stc_word_pqueue_top(&raw const self.words) as *const T
        else: &raw const *unsafe { stc_slot_view(*stc_slot_pqueue_top(&raw const self.queue) as *const StcSlot[T]) }

    /// Observes the top value, or `None` when empty.
    pub fn peek() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.top_place() })

impl[T] Drop for PriorityQueue[T]:
    move fn drop():
        // The engine's pointer array is its own; walk it and release every
        // slot before the engine frees the array. The word heap holds no
        // resource.
        let count = self.queue.size as i32
        for index in 0..count:
            unsafe { stc_slot_release(unsafe { self.queue.data[index] } as *mut StcSlot[T]) }
        unsafe { stc_slot_pqueue_drop(&raw const self.queue) }
        unsafe { stc_word_pqueue_drop(&raw const self.words) }
