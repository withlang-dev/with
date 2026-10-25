// std.collections.queue — Queue[T]: a first-in-first-out queue over the
// migrated STC `queue` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the
// facade map's primary engine, a ring buffer that grows). Two shapes serve
// it (D148): an integer scalar is stored inline as one word
// (`stc_word_queue`, no allocation per element); any other `T` rides the
// slot shape (`stc_slot_queue` holds pointers to facade-owned slots,
// std.collections.stc_slot). The shape is chosen at compile time by the
// element type; both engine handles live in the facade, the unused one
// empty.
//
// Complexity contract: O(1) amortized push and pop, O(1) front and back.

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
use std.collections.stc_slot.stc_slot_unordered
use std.collections.stc_word.stc_is_word
use std.collections.stc_word.stc_to_word
use std.collections.stc_word.stc_from_word
use rt.rt_core

/// `push` enqueues at the back; `pop` transfers the front out (D27);
/// `front` and `back` observe.
pub type Queue[T] { slots: stc_slot_queue, words: stc_word_queue }

pub fn Queue.new[T]() -> Queue[T]:
    Queue { slots: stc_slot_queue_init(), words: stc_word_queue_init() }

impl[T] Queue[T]:
    pub fn len() -> isize:
        comptime if stc_is_word[T](): self.words.size() as isize
        else: self.slots.size() as isize
    pub fn is_empty() -> bool: self.len() == 0

    pub mut fn push(value: T):
        comptime if stc_is_word[T]():
            self.words.push(stc_to_word(value))
        else:
            unsafe { stc_slot_queue_push(&raw mut self.slots, stc_slot_new(value, stc_slot_unordered, stc_slot_unhashed)) }

    /// Transfers the front value out, or `None` when empty.
    pub mut fn pop() -> Option[T]:
        if self.len() == 0: return None
        comptime if stc_is_word[T]():
            let word = unsafe { *stc_word_queue_front(&raw const self.words) }
            self.words.pop()
            Some(stc_from_word(word))
        else:
            let slot = unsafe { *stc_slot_queue_front(&raw const self.slots) } as *mut StcSlot[T]
            self.slots.pop()
            Some(unsafe { stc_slot_take(slot) })

    unsafe fn front_place() -> *const T:
        comptime if stc_is_word[T](): stc_word_queue_front(&raw const self.words) as *const T
        else: &raw const *unsafe { stc_slot_view(*stc_slot_queue_front(&raw const self.slots) as *const StcSlot[T]) }

    unsafe fn back_place() -> *const T:
        comptime if stc_is_word[T](): stc_word_queue_back(&raw const self.words) as *const T
        else: &raw const *unsafe { stc_slot_view(*stc_slot_queue_back(&raw const self.slots) as *const StcSlot[T]) }

    /// Observes the front value, or `None` when empty.
    pub fn front() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.front_place() })

    /// Observes the back value, or `None` when empty.
    pub fn back() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.back_place() })

    /// Drops every value and empties the queue.
    pub mut fn clear():
        while self.len() > 0:
            let value = self.pop().unwrap()
            drop(value)

    /// Views of the values, front to back (D44: traversal observes).
    pub fn iter() -> QueueIter[T]:
        comptime if stc_is_word[T]():
            QueueIter { words: self.words.begin(), slots: stc_slot_queue_iter.zeroed() }
        else:
            QueueIter { words: stc_word_queue_iter.zeroed(), slots: self.slots.begin() }

impl[T] Drop for Queue[T]:
    move fn drop():
        comptime if stc_is_word[T]():
            unsafe { stc_word_queue_drop(&raw const self.words) }
            unsafe { stc_slot_queue_drop(&raw const self.slots) }
        else:
            var cursor = self.slots.begin()
            while cursor.ref as i64 != 0:
                unsafe { stc_slot_release(unsafe { *cursor.ref } as *mut StcSlot[T]) }
                cursor.next()
            unsafe { stc_slot_queue_drop(&raw const self.slots) }
            unsafe { stc_word_queue_drop(&raw const self.words) }

pub type QueueIter[T] ephemeral { words: stc_word_queue_iter, slots: stc_slot_queue_iter }

impl[T] QueueIter[T]:
    pub mut fn next() -> Option[&T]:
        comptime if stc_is_word[T]():
            if self.words.ref as i64 == 0: return None
            let place = self.words.ref as *const T
            self.words.next()
            Some(unsafe { &*place })
        else:
            if self.slots.ref as i64 == 0: return None
            let slot = unsafe { *self.slots.ref } as *const StcSlot[T]
            self.slots.next()
            Some(unsafe { stc_slot_view(slot) })
