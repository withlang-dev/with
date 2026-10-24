// std.collections.stack — Stack[T]: a last-in-first-out stack over the
// migrated STC `stack` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the
// facade map's primary engine, a growable array without the vector's
// insert-anywhere surface). Two shapes serve it (D148): an integer scalar
// is stored inline as one word (`stc_word_stack`, no allocation per
// element); any other `T` rides the slot shape (`stc_slot_stack` holds
// pointers to facade-owned slots, std.collections.stc_slot). The shape is
// chosen at compile time by the element type; both engine handles live in
// the facade, the unused one empty.
//
// Complexity contract: O(1) amortized push and pop, O(1) peek and indexed
// access.

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

/// `peek` and `get(i)` observe, `pop` transfers (D27); index 0 is the
/// bottom and an out-of-range index panics (§15.11).
pub type Stack[T] { slots: stc_slot_stack, words: stc_word_stack }

pub fn Stack.new[T]() -> Stack[T]:
    Stack { slots: stc_slot_stack_init(), words: stc_word_stack_init() }

impl[T] Stack[T]:
    pub fn len() -> isize:
        comptime if stc_is_word[T](): unsafe { stc_word_stack_size(&raw const self.words) } as isize
        else: unsafe { stc_slot_stack_size(&raw const self.slots) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    pub mut fn push(value: T):
        comptime if stc_is_word[T]():
            unsafe { stc_word_stack_push(&raw mut self.words, stc_to_word(value)) }
        else:
            unsafe { stc_slot_stack_push(&raw mut self.slots, stc_slot_new(value, stc_slot_unordered, stc_slot_unhashed)) }

    /// Transfers the top value out, or `None` when empty.
    pub mut fn pop() -> Option[T]:
        if self.len() == 0: return None
        comptime if stc_is_word[T]():
            let word = unsafe { *stc_word_stack_top(&raw const self.words) }
            unsafe { stc_word_stack_pop(&raw mut self.words) }
            Some(stc_from_word(word))
        else:
            let slot = unsafe { *stc_slot_stack_top(&raw const self.slots) } as *mut StcSlot[T]
            unsafe { stc_slot_stack_pop(&raw mut self.slots) }
            Some(unsafe { stc_slot_take(slot) })

    // The element's place in whichever array holds it (D22: a word element
    // is read where it sits, the engine's own storage).
    unsafe fn place(index: isize) -> *const T:
        comptime if stc_is_word[T](): stc_word_stack_at(&raw const self.words, index as i64) as *const T
        else: &raw const *unsafe { stc_slot_view(*stc_slot_stack_at(&raw const self.slots, index as i64) as *const StcSlot[T]) }

    /// Observes the top value, or `None` when empty.
    pub fn peek() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.place(self.len() - 1) })

    /// Observes the value at `index` from the bottom; panics out of range.
    pub fn get(index: isize) -> &T from self:
        assert(index >= 0 and index < self.len(), "Stack index out of bounds")
        unsafe { &*self.place(index) }

    /// Drops every value and empties the stack.
    pub mut fn clear():
        while self.len() > 0:
            let value = self.pop().unwrap()
            drop(value)

    /// Views of the values, bottom to top (D44: traversal observes).
    pub fn iter() -> StackIter[T]:
        StackIter { stack: (&raw const *self) as i64, index: 0, len: self.len() }

impl[T] Drop for Stack[T]:
    move fn drop():
        comptime if stc_is_word[T]():
            unsafe { stc_word_stack_drop(&raw const self.words) }
            unsafe { stc_slot_stack_drop(&raw const self.slots) }
        else:
            let count = self.len()
            for index in 0..count:
                unsafe { stc_slot_release(unsafe { *stc_slot_stack_at(&raw const self.slots, index as i64) } as *mut StcSlot[T]) }
            unsafe { stc_slot_stack_drop(&raw const self.slots) }
            unsafe { stc_word_stack_drop(&raw const self.words) }

pub type StackIter[T] ephemeral { stack: i64, index: isize, len: isize }

impl[T] StackIter[T]:
    pub mut fn next() -> Option[&T]:
        if self.index >= self.len: return None
        let owner = self.stack as *const Stack[T]
        let place = unsafe { (*owner).place(self.index) }
        self.index = self.index + 1
        Some(unsafe { &*place })
