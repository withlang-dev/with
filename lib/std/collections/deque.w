// std.collections.deque — Deque[T]: a double-ended queue over the migrated
// STC `deque` (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the facade
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
use std.collections.stc_slot.stc_slot_prefix
use std.collections.stc_slot.stc_slot_unhashed
use std.collections.stc_slot.stc_slot_unordered
use rt.rt_core

/// `front`/`back`/`get(i)` observe, `pop_front`/`pop_back` transfer (D27);
/// an out-of-range index panics (§15.11: absence is a bug, not a value).
/// `d[i]` is the spelling once a generic type can implement IndexPlace
/// (#2560).
pub type Deque[T] { slots: stc_slot_deque, words: stc_word_deque }

pub fn Deque.new[T]() -> Deque[T]:
    Deque { slots: stc_slot_deque_init(), words: stc_word_deque_init() }

// The integer scalars the word shape stores inline, by the element type's
// name (`comptime if` instantiates only the branch taken).
fn deque_is_word[T]() -> bool:
    comptime if T.name() == "i64" or T.name() == "u64" or T.name() == "i32" or T.name() == "u32" or T.name() == "i16" or T.name() == "u16" or T.name() == "i8" or T.name() == "u8" or T.name() == "isize" or T.name() == "usize": true
    else: false

fn deque_to_word[T](value: T) -> u64:
    comptime if T.name() == "i64": value as u64
    else if T.name() == "u64": value
    else if T.name() == "i32": (value as i64) as u64
    else if T.name() == "u32": value as u64
    else if T.name() == "i16": (value as i64) as u64
    else if T.name() == "u16": value as u64
    else if T.name() == "i8": (value as i64) as u64
    else if T.name() == "u8": value as u64
    else if T.name() == "isize": (value as i64) as u64
    else if T.name() == "usize": value as u64
    else: 0

fn deque_from_word[T](word: u64) -> T:
    comptime if T.name() == "i64": word as i64
    else if T.name() == "u64": word
    else if T.name() == "i32": (word as i64) as i32
    else if T.name() == "u32": word as u32
    else if T.name() == "i16": (word as i64) as i16
    else if T.name() == "u16": word as u16
    else if T.name() == "i8": (word as i64) as i8
    else if T.name() == "u8": word as u8
    else if T.name() == "isize": (word as i64) as isize
    else if T.name() == "usize": word as usize
    else: panic("Deque: not a word element")

impl[T] Deque[T]:
    pub fn len() -> isize:
        comptime if deque_is_word[T](): unsafe { stc_word_deque_size(&raw const self.words) } as isize
        else: unsafe { stc_slot_deque_size(&raw const self.slots) } as isize
    pub fn is_empty() -> bool: self.len() == 0

    unsafe fn new_slot(value: T) -> *mut StcSlot[T]:
        let slot = with_alloc(sizeof[StcSlot[T]]() as i64) as *mut StcSlot[T]
        *slot = StcSlot { prefix: stc_slot_prefix(stc_slot_unordered, stc_slot_unhashed), value: value }
        slot

    pub mut fn push_back(value: T):
        comptime if deque_is_word[T]():
            unsafe { stc_word_deque_push_back(&raw mut self.words, deque_to_word(value) as c_ulonglong) }
        else:
            let slot = unsafe { self.new_slot(value) }
            unsafe { stc_slot_deque_push_back(&raw mut self.slots, slot as *mut stc_slot_head) }

    pub mut fn push_front(value: T):
        comptime if deque_is_word[T]():
            unsafe { stc_word_deque_push_front(&raw mut self.words, deque_to_word(value) as c_ulonglong) }
        else:
            let slot = unsafe { self.new_slot(value) }
            unsafe { stc_slot_deque_push_front(&raw mut self.slots, slot as *mut stc_slot_head) }

    unsafe fn take(slot: *mut StcSlot[T]) -> T:
        var owned = slot
        let value: T = move owned.value
        with_free(slot as *mut u8)
        value

    /// Transfers the last value out, or `None` when empty.
    pub mut fn pop_back() -> Option[T]:
        if self.len() == 0: return None
        comptime if deque_is_word[T]():
            let word = unsafe { *stc_word_deque_back(&raw const self.words) } as u64
            unsafe { stc_word_deque_pop_back(&raw mut self.words) }
            Some(deque_from_word(word))
        else:
            let slot = unsafe { *stc_slot_deque_back(&raw const self.slots) } as *mut StcSlot[T]
            unsafe { stc_slot_deque_pop_back(&raw mut self.slots) }
            Some(unsafe { self.take(slot) })

    /// Transfers the first value out, or `None` when empty.
    pub mut fn pop_front() -> Option[T]:
        if self.len() == 0: return None
        comptime if deque_is_word[T]():
            let word = unsafe { *stc_word_deque_front(&raw const self.words) } as u64
            unsafe { stc_word_deque_pop_front(&raw mut self.words) }
            Some(deque_from_word(word))
        else:
            let slot = unsafe { *stc_slot_deque_front(&raw const self.slots) } as *mut StcSlot[T]
            unsafe { stc_slot_deque_pop_front(&raw mut self.slots) }
            Some(unsafe { self.take(slot) })

    // The element's place in whichever ring holds it (D22: a word element
    // is read where it sits, the engine's own storage).
    unsafe fn place(index: isize) -> *const T:
        comptime if deque_is_word[T](): stc_word_deque_at(&raw const self.words, index as c_long) as *const T
        else: &raw const (*(*stc_slot_deque_at(&raw const self.slots, index as c_long) as *const StcSlot[T])).value

    pub fn front() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.place(0) })

    pub fn back() -> Option[&T] from self:
        if self.len() == 0: return None
        Some(unsafe { &*self.place(self.len() - 1) })

    /// Observes the value at `index`; panics out of range (D27).
    pub fn get(index: isize) -> &T from self:
        assert(index >= 0 and index < self.len(), "Deque index out of bounds")
        unsafe { &*self.place(index) }

    /// Drops every value and empties the deque.
    pub mut fn clear():
        while self.len() > 0:
            let value = self.pop_back().unwrap()
            drop(value)

    /// Views of the values, front to back (D44: traversal observes).
    pub fn iter() -> DequeIter[T]:
        DequeIter { deque: (&raw const *self) as i64, index: 0, len: self.len() }

impl[T] Drop for Deque[T]:
    move fn drop():
        comptime if deque_is_word[T]():
            unsafe { stc_word_deque_drop(&raw const self.words) }
            unsafe { stc_slot_deque_drop(&raw const self.slots) }
        else:
            let count = self.len()
            for index in 0..count:
                let slot = unsafe { *stc_slot_deque_at(&raw const self.slots, index as c_long) } as *mut StcSlot[T]
                var owned = slot
                let value: T = unsafe { move owned.value }
                drop(value)
                with_free(slot as *mut u8)
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
