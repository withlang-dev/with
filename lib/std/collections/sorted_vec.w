// std.collections.sorted_vec — SortedVec[T]: a sorted contiguous collection
// over the migrated c-algorithms sorted array (docs/stdlib_sourcing_plan.md,
// Phase 1). The engine keeps an array of slot pointers in comparator order;
// the facade owns every value (std.collections.engine_slot).
//
// Complexity contract: O(log n) search, O(n) insert and remove (the engine
// shifts pointers), O(1) indexed access.

use std.option
use std.traits
use std.c_algorithms.defs
use std.c_algorithms.sortedarray
use std.collections.engine_slot.Slot
use std.collections.engine_slot.slot_compare

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8

/// Values kept in ascending `Ord` order (D41: `cmp` backs the `<`/`>` the
/// comparator applies to views). `get(i)` observes the i-th value;
/// `remove(i)` transfers it out (D27).
pub type SortedVec[T] { array: *mut _SortedArray }

pub fn SortedVec.new[T: Ord]() -> SortedVec[T]:
    let array = sortedarray_new(0 as c_uint, slot_compare)
    assert(array as i64 != 0)
    SortedVec { array: array }

impl[T: Ord] SortedVec[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const Slot[T])).value }
            let right = unsafe { &(*(b as *const Slot[T])).value }
            if left < right: -1 else if left > right: 1 else: 0

    pub fn len() -> i32: unsafe { sortedarray_length(self.array) } as i32
    pub fn is_empty() -> bool: self.len() == 0

    fn slot_at(index: i32) -> *mut Slot[T]:
        assert(index >= 0 and index < self.len())
        unsafe { sortedarray_get(self.array, index as c_uint) } as *mut Slot[T]

    /// Inserts `value` at its sorted position, after any equal values.
    pub mut fn insert(value: T) -> Unit:
        let slot = unsafe { with_alloc(sizeof[Slot[T]]() as i64) } as *mut Slot[T]
        unsafe { *slot = Slot { compare: self.comparator(), value: value } }
        assert(unsafe { sortedarray_insert(self.array, slot as *mut c_void) } != 0)

    /// Observes the value at `index`; panics out of range (D27).
    pub fn get(index: i32) -> &T:
        unsafe { &(*self.slot_at(index)).value }

    /// Transfers the value at `index` out; panics out of range.
    pub mut fn remove(index: i32) -> T:
        var slot = self.slot_at(index)
        assert(unsafe { sortedarray_remove(self.array, index as c_uint) } != 0)
        let value: T = unsafe { move slot.value }
        unsafe { with_free(slot as *mut u8) }
        value

    /// The index of a value equal to `value`, if any (binary search).
    pub fn index_of(value: &T) -> Option[i32]:
        // The engine compares the probe against stored slots through the
        // probe's comparator, so the probe is a slot too: the comparator
        // and a byte image of `value` that is never read back as owned.
        let probe = unsafe { with_alloc(sizeof[Slot[T]]() as i64) } as *mut Slot[T]
        unsafe { (*probe).compare = self.comparator() }
        unsafe { with_memcpy(&raw mut (*probe).value as *mut u8, &raw const *value as *const u8, sizeof[T]() as i64) }
        let found = unsafe { sortedarray_index_of(self.array, probe as *mut c_void) }
        unsafe { with_free(probe as *mut u8) }
        if found < 0: None else: Some(found as i32)

    pub fn contains(value: &T) -> bool: self.index_of(value).is_some()

    /// Drops every value and empties the collection.
    pub mut fn clear() -> Unit:
        for index in 0..self.len():
            var slot = self.slot_at(index)
            let value: T = unsafe { move slot.value }
            drop(value)
            unsafe { with_free(slot as *mut u8) }
        unsafe { sortedarray_clear(self.array) }

    /// An ephemeral cursor over the values in order, yielding views.
    pub fn iter() -> SortedVecIter[T]:
        SortedVecIter { array: self.array as i64, index: 0, len: self.len() }

impl[T] Drop for SortedVec[T]:
    move fn drop():
        let len = unsafe { sortedarray_length(self.array) } as i32
        for index in 0..len:
            var slot = unsafe { sortedarray_get(self.array, index as c_uint) } as *mut Slot[T]
            let value: T = unsafe { move slot.value }
            drop(value)
            unsafe { with_free(slot as *mut u8) }
        unsafe { sortedarray_free(self.array) }

/// Cursor over a SortedVec; obtain via `sorted.iter()`. `next()` yields
/// `Some(&T)` in ascending order, then `None`.
pub type SortedVecIter[T] ephemeral { array: i64, index: i32, len: i32 }

impl[T] SortedVecIter[T]:
    pub mut fn next() -> Option[&T]:
        if self.index >= self.len: return None
        let slot = unsafe { sortedarray_get(self.array as *mut _SortedArray, self.index as c_uint) } as *const Slot[T]
        self.index = self.index + 1
        Some(unsafe { &(*slot).value })
