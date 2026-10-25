// std.collections.unordered_set — UnorderedSet[T]: a hash set in no stated
// order over the migrated STC `hset` (docs/proposals/stdlib_sourcing_plan.md,
// Phase 3; D149: `HashSet` keeps rt_core's insertion-ordered layout, this
// is the unordered one for hot paths that need no order, the way Zig
// ships both). Two shapes serve it (D148): an integer scalar is the
// engine's own word key (`stc_word_set`: the engine hashes and compares it
// itself, no allocation per element or per probe); any other `T` rides the
// slot shape (the engine, Robin Hood hashing, holds slot pointers,
// std.collections.stc_slot; the facade owns every value, keys hash through
// `std.hash.hash_of` and compare through `==`, D96). The shape is chosen at
// compile time by the element type; both engine handles live in the facade,
// the unused one empty.
//
// Complexity contract: O(1) expected insert, lookup and remove; a removal
// allocates nothing.

use std.hash
use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.collections.stc_slot.StcSlot
use std.collections.stc_slot.stc_slot_probe
use std.collections.stc_slot.stc_slot_discard_probe
use std.collections.stc_slot.stc_slot_new
use std.collections.stc_slot.stc_slot_view
use std.collections.stc_slot.stc_slot_take
use std.collections.stc_slot.stc_slot_release
use std.collections.stc_word.stc_is_word
use std.collections.stc_word.stc_to_word
use std.collections.stc_word.stc_from_word
use rt.rt_core

/// `contains` and `get` observe; `insert` owns its input and refuses an
/// equal value; `remove` transfers (D27). Traversal observes, in no order.
pub type UnorderedSet[T] { set: stc_slot_set, words: stc_word_set }

pub fn UnorderedSet.new[T: Key]() -> UnorderedSet[T]:
    UnorderedSet { set: stc_slot_set_init(), words: stc_word_set_init() }

impl[T: Key] UnorderedSet[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const StcSlot[T])).value }
            let right = unsafe { &(*(b as *const StcSlot[T])).value }
            if left == right: 0 else: 1

    fn hasher() -> fn(*const u8) -> u64:
        p => hash_of(unsafe { &(*(p as *const StcSlot[T])).value })

    pub fn len() -> isize:
        comptime if stc_is_word[T](): self.words.size() as isize
        else: self.set.size() as isize
    pub fn is_empty() -> bool: self.len() == 0

    fn find_slot(value: &T) -> *mut StcSlot[T]:
        let probe = stc_slot_probe(value, self.comparator(), self.hasher())
        let found = unsafe { stc_slot_set_get(&raw const self.set, probe) }
        stc_slot_discard_probe(probe)
        if found as i64 == 0: null else: unsafe { *found } as *mut StcSlot[T]

    // The word key of a value (the word shape only).
    fn word(value: &T) -> u64: stc_to_word(*value)

    /// Inserts `value`; returns false (and drops the value) when an equal
    /// value is already present.
    pub mut fn insert(value: T) -> bool:
        comptime if stc_is_word[T]():
            self.words.insert(stc_to_word(value)).inserted
        else:
            let slot = stc_slot_new(value, self.comparator(), self.hasher())
            let result = unsafe { stc_slot_set_insert(&raw mut self.set, slot) }
            if result.inserted: return true
            unsafe { stc_slot_release(slot as *mut StcSlot[T]) }
            false

    pub fn contains(value: &T) -> bool:
        comptime if stc_is_word[T](): self.words.contains(self.word(value))
        else: self.find_slot(value) as i64 != 0

    /// Observes the stored value equal to `value`, if any (D22: a word
    /// element is read where it sits, the engine's own table).
    pub fn get(value: &T) -> Option[&T] from self:
        comptime if stc_is_word[T]():
            let place = unsafe { stc_word_set_get(&raw const self.words, self.word(value)) }
            if place as i64 == 0: None else: Some(unsafe { &*(place as *const T) })
        else:
            let slot = self.find_slot(value)
            if slot as i64 == 0: None else: Some(unsafe { &(*slot).value })

    /// Transfers the value equal to `value` out, if any.
    pub mut fn remove(value: &T) -> Option[T]:
        comptime if stc_is_word[T]():
            let word = self.word(value)
            if self.words.erase(word) == 0: None
            else: Some(stc_from_word(word))
        else:
            let slot = self.find_slot(value)
            if slot as i64 == 0: return None
            let probe = stc_slot_probe(value, self.comparator(), self.hasher())
            assert(unsafe { stc_slot_set_erase(&raw mut self.set, probe) } != 0)
            stc_slot_discard_probe(probe)
            Some(unsafe { stc_slot_take(slot) })

    /// Drops every value and empties the set.
    pub mut fn clear():
        comptime if stc_is_word[T]():
            self.words.clear()
        else:
            var cursor = self.set.begin()
            while cursor.ref as i64 != 0:
                unsafe { stc_slot_release(unsafe { *cursor.ref } as *mut StcSlot[T]) }
                cursor.next()
            self.set.clear()

    /// Views of the values, in no stated order (D44: traversal observes).
    pub fn iter() -> UnorderedSetIter[T]:
        comptime if stc_is_word[T]():
            UnorderedSetIter { cursor: stc_slot_set_iter.zeroed(), words: self.words.begin() }
        else:
            UnorderedSetIter { cursor: self.set.begin(), words: stc_word_set_iter.zeroed() }

impl[T] Drop for UnorderedSet[T]:
    move fn drop():
        var cursor = self.set.begin()
        while cursor.ref as i64 != 0:
            unsafe { stc_slot_release(unsafe { *cursor.ref } as *mut StcSlot[T]) }
            cursor.next()
        unsafe { stc_slot_set_drop(&raw const self.set) }
        unsafe { stc_word_set_drop(&raw const self.words) }

pub type UnorderedSetIter[T] ephemeral { cursor: stc_slot_set_iter, words: stc_word_set_iter }

impl[T] UnorderedSetIter[T]:
    pub mut fn next() -> Option[&T]:
        comptime if stc_is_word[T]():
            if self.words.ref as i64 == 0: return None
            let place = self.words.ref as *const T
            self.words.next()
            Some(unsafe { &*place })
        else:
            if self.cursor.ref as i64 == 0: return None
            let slot = unsafe { *self.cursor.ref } as *const StcSlot[T]
            self.cursor.next()
            Some(unsafe { stc_slot_view(slot) })
