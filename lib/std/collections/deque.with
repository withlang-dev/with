// std.collections.deque — Deque[T]: a double-ended queue over the migrated
// STC `deque` (stdlib_sourcing_plan.md, Phase 3; the facade
// map's primary engine, a ring buffer). Two shapes of the engine serve it
// (D148, as ruled on its brief): an integer scalar — i8..i64, u8..u64,
// isize, usize — is stored inline as one word in the engine's own ring
// (`stc_word_deque`, no allocation per element); any other `T` rides the
// slot shape (`stc_slot_deque` holds pointers to facade-owned slots,
// std.collections.stc_slot, one allocation per element). The shape is
// chosen at compile time by the element type; both engine handles live in
// the facade, the unused one empty.
//
// Complexity contract: O(1) amortized push and pop at either end, O(1)
// indexed access. The word shape is the fast one: measure before putting
// a struct in a hot deque.

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

/// `front`/`back`/`d[i]` observe, `pop_front`/`pop_back` transfer (D27);
/// an out-of-range index panics (§15.11: absence is a bug, not a value).
/// `d[i]` is the element's view (`IndexGet`, #2560): `d[i] = v` is not a
/// store a deque offers.
pub type Deque[T] { slots: stc_slot_deque, words: stc_word_deque }

pub fn Deque.new[T]() -> Deque[T]:
    Deque { slots: stc_slot_deque_init(), words: stc_word_deque_init() }

impl[T] Deque[T]:
    pub fn len() -> isize:
        comptime if stc_is_word[T](): self.words.size() as isize
        else: self.slots.size() as isize
    pub fn is_empty() -> bool: self.len() == 0

    pub mut fn push_back(value: T):
        comptime if stc_is_word[T]():
            self.words.push_back(stc_to_word(value))
        else:
            unsafe { stc_slot_deque_push_back(&raw mut self.slots, stc_slot_new(value, stc_slot_unordered, stc_slot_unhashed)) }

    pub mut fn push_front(value: T):
        comptime if stc_is_word[T]():
            self.words.push_front(stc_to_word(value))
        else:
            unsafe { stc_slot_deque_push_front(&raw mut self.slots, stc_slot_new(value, stc_slot_unordered, stc_slot_unhashed)) }

    /// Transfers the last value out, or `None` when empty.
    pub mut fn pop_back() -> Option[T]:
        if self.len() == 0: return None
        comptime if stc_is_word[T]():
            let word = unsafe { *stc_word_deque_back(&raw const self.words) }
            self.words.pop_back()
            Some(stc_from_word(word))
        else:
            let slot = unsafe { *stc_slot_deque_back(&raw const self.slots) } as *mut StcSlot[T]
            self.slots.pop_back()
            Some(unsafe { stc_slot_take(slot) })

    /// Transfers the first value out, or `None` when empty.
    pub mut fn pop_front() -> Option[T]:
        if self.len() == 0: return None
        comptime if stc_is_word[T]():
            let word = unsafe { *stc_word_deque_front(&raw const self.words) }
            self.words.pop_front()
            Some(stc_from_word(word))
        else:
            let slot = unsafe { *stc_slot_deque_front(&raw const self.slots) } as *mut StcSlot[T]
            self.slots.pop_front()
            Some(unsafe { stc_slot_take(slot) })

    // The element's place in whichever ring holds it (D22: a word element
    // is read where it sits, the engine's own storage).
    unsafe fn place(index: isize) -> *const T:
        comptime if stc_is_word[T](): stc_word_deque_at(&raw const self.words, index as i64) as *const T
        else: &raw const *unsafe { stc_slot_view(*stc_slot_deque_at(&raw const self.slots, index as i64) as *const StcSlot[T]) }

    pub fn front() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.place(0) })

    pub fn back() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.place(self.len() - 1) })

    /// Drops every value and empties the deque.
    pub mut fn clear():
        while self.len() > 0:
            let value = self.pop_back().unwrap()
            drop(value)

    /// Views of the values, front to back (D44: traversal observes).
    pub fn iter() -> DequeIter[T]:
        DequeIter { deque: (&raw const *self) as i64, index: 0, len: self.len() }

/// `d[i]` observes the value at `index` (D27's element view, #2560); panics
/// out of range. `d.get(i)` is the same method by name.
impl[T] IndexGet[isize, &T] for Deque[T]:
    fn get(self: &Self, index: isize) -> &T from self:
        assert(index >= 0 and index < self.len(), "Deque index out of bounds")
        unsafe { &*self.place(index) }

impl[T] Drop for Deque[T]:
    move fn drop():
        comptime if stc_is_word[T]():
            unsafe { stc_word_deque_drop(&raw const self.words) }
            unsafe { stc_slot_deque_drop(&raw const self.slots) }
        else:
            let count = self.len()
            for index in 0..count:
                unsafe { stc_slot_release(unsafe { *stc_slot_deque_at(&raw const self.slots, index as i64) } as *mut StcSlot[T]) }
            unsafe { stc_slot_deque_drop(&raw const self.slots) }
            unsafe { stc_word_deque_drop(&raw const self.words) }

pub type DequeIter[T] ephemeral { deque: i64, index: isize, len: isize }

impl[T] DequeIter[T]:
    pub mut fn next() -> Option[&T]:
        if self.index >= self.len: return None
        let owner = self.deque as *const Deque[T]
        let place = unsafe { (*owner).place(self.index) }
        self.index = self.index + 1
        Some(unsafe { &*place })
