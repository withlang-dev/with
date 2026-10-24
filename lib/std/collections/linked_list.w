// std.collections.linked_list — LinkedList[T]: a singly linked list over
// the migrated STC `list` (docs/proposals/stdlib_sourcing_plan.md, Phase 3;
// the facade map's primary engine for the linked list, a circular
// singly-linked list that pushes at both ends and pops at the front). Two
// shapes serve it (D148): an integer scalar is stored inline in the node
// as one word (`stc_word_list`, its sort is the engine's own `<`);
// any other `T` rides the slot shape (`stc_slot_list` nodes hold pointers to
// facade-owned slots, std.collections.stc_slot). The shape is chosen at
// compile time by the element type; both engine handles live in the
// facade, the unused one empty. The facade counts elements: the engine's
// `count` walks the list.
//
// Complexity contract: O(1) push at either end and pop at the front,
// O(1) front and back, O(n) reverse, O(n log n) sort.

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.StcSlotPrefix
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

/// `front` and `back` observe, `pop_front` transfers (D27); traversal
/// observes, front to back.
pub type LinkedList[T] { slots: stc_slot_list, words: stc_word_list, count: isize }

pub fn LinkedList.new[T]() -> LinkedList[T]:
    LinkedList { slots: stc_slot_list_init(), words: stc_word_list_init(), count: 0 }

impl[T] LinkedList[T]:
    pub fn len() -> isize: self.count
    pub fn is_empty() -> bool: self.count == 0

    pub mut fn push_back(value: T):
        comptime if stc_is_word[T]():
            unsafe { stc_word_list_push_back(&raw mut self.words, stc_to_word(value) as i64) }
        else:
            unsafe { stc_slot_list_push_back(&raw mut self.slots, stc_slot_new(value, stc_slot_unordered, stc_slot_unhashed)) }
        self.count = self.count + 1

    pub mut fn push_front(value: T):
        comptime if stc_is_word[T]():
            unsafe { stc_word_list_push_front(&raw mut self.words, stc_to_word(value) as i64) }
        else:
            unsafe { stc_slot_list_push_front(&raw mut self.slots, stc_slot_new(value, stc_slot_unordered, stc_slot_unhashed)) }
        self.count = self.count + 1

    /// Transfers the front value out, or `None` when empty.
    pub mut fn pop_front() -> Option[T]:
        if self.count == 0: return None
        self.count = self.count - 1
        comptime if stc_is_word[T]():
            let word = unsafe { *stc_word_list_front(&raw const self.words) }
            unsafe { stc_word_list_pop_front(&raw mut self.words) }
            Some(stc_from_word(word as u64))
        else:
            let slot = unsafe { *stc_slot_list_front(&raw const self.slots) } as *mut StcSlot[T]
            unsafe { stc_slot_list_pop_front(&raw mut self.slots) }
            Some(unsafe { stc_slot_take(slot) })

    unsafe fn front_place() -> *const T:
        comptime if stc_is_word[T](): stc_word_list_front(&raw const self.words) as *const T
        else: &raw const *unsafe { stc_slot_view(*stc_slot_list_front(&raw const self.slots) as *const StcSlot[T]) }

    unsafe fn back_place() -> *const T:
        comptime if stc_is_word[T](): stc_word_list_back(&raw const self.words) as *const T
        else: &raw const *unsafe { stc_slot_view(*stc_slot_list_back(&raw const self.slots) as *const StcSlot[T]) }

    /// Observes the front value, or `None` when empty.
    pub fn front() -> Option[&T] from self:
        if self.count == 0: return None
        Some(unsafe { &*self.front_place() })

    /// Observes the back value, or `None` when empty.
    pub fn back() -> Option[&T] from self:
        if self.count == 0: return None
        Some(unsafe { &*self.back_place() })

    /// Reverses the list in place (the engine relinks the nodes).
    pub mut fn reverse():
        comptime if stc_is_word[T](): unsafe { stc_word_list_reverse(&raw mut self.words) }
        else: unsafe { stc_slot_list_reverse(&raw mut self.slots) }

    /// Drops every value and empties the list.
    pub mut fn clear():
        while self.count > 0:
            let value = self.pop_front().unwrap()
            drop(value)

    /// Views of the values, front to back (D44: traversal observes).
    pub fn iter() -> LinkedListIter[T]:
        comptime if stc_is_word[T]():
            LinkedListIter { words: unsafe { stc_word_list_begin(&raw const self.words) }, slots: stc_slot_list_iter.zeroed() }
        else:
            LinkedListIter { words: stc_word_list_iter.zeroed(), slots: unsafe { stc_slot_list_begin(&raw const self.slots) } }

impl[T: Ord] LinkedList[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const StcSlot[T])).value }
            let right = unsafe { &(*(b as *const StcSlot[T])).value }
            if left < right: -1 else if left > right: 1 else: 0

    // An unsigned 64-bit word has its sign bit flipped around the engine's
    // signed sort, so the order is the value's; the nodes keep the raw
    // bits otherwise, which the views read in place.
    unsafe fn flip_sign_bits():
        var cursor = stc_word_list_begin(&raw const self.words)
        while cursor.ref as i64 != 0:
            *cursor.ref = ((*cursor.ref as u64) ^ 9223372036854775808) as i64
            stc_word_list_next(&raw mut cursor)

    /// Sorts ascending by `Ord` (D41): a word list by the engine's own `<`;
    /// a slot list through the facade's comparator, which every slot is
    /// pointed at first (the nodes were pushed without an order). Not
    /// stable.
    pub mut fn sort():
        comptime if T.name() == "u64" or T.name() == "usize":
            unsafe { self.flip_sign_bits() }
            unsafe { stc_word_list_sort(&raw mut self.words) }
            unsafe { self.flip_sign_bits() }
        else if stc_is_word[T]():
            unsafe { stc_word_list_sort(&raw mut self.words) }
        else:
            var cursor = unsafe { stc_slot_list_begin(&raw const self.slots) }
            while cursor.ref as i64 != 0:
                let prefix = unsafe { *cursor.ref } as *mut StcSlotPrefix
                unsafe { (*prefix).compare = self.comparator() }
                unsafe { stc_slot_list_next(&raw mut cursor) }
            unsafe { stc_slot_list_sort(&raw mut self.slots) }

impl[T] Drop for LinkedList[T]:
    move fn drop():
        comptime if stc_is_word[T]():
            unsafe { stc_word_list_drop(&raw const self.words) }
            unsafe { stc_slot_list_drop(&raw const self.slots) }
        else:
            var cursor = unsafe { stc_slot_list_begin(&raw const self.slots) }
            while cursor.ref as i64 != 0:
                unsafe { stc_slot_release(unsafe { *cursor.ref } as *mut StcSlot[T]) }
                unsafe { stc_slot_list_next(&raw mut cursor) }
            unsafe { stc_slot_list_drop(&raw const self.slots) }
            unsafe { stc_word_list_drop(&raw const self.words) }

pub type LinkedListIter[T] ephemeral { words: stc_word_list_iter, slots: stc_slot_list_iter }

impl[T] LinkedListIter[T]:
    pub mut fn next() -> Option[&T]:
        comptime if stc_is_word[T]():
            if self.words.ref as i64 == 0: return None
            let place = self.words.ref as *const T
            unsafe { stc_word_list_next(&raw mut self.words) }
            Some(unsafe { &*place })
        else:
            if self.slots.ref as i64 == 0: return None
            let slot = unsafe { *self.slots.ref } as *const StcSlot[T]
            unsafe { stc_slot_list_next(&raw mut self.slots) }
            Some(unsafe { stc_slot_view(slot) })
