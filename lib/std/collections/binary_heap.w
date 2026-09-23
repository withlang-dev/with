// std.collections.binary_heap — BinaryHeap[T]: an owning heap over the
// migrated c-algorithms binary heap (docs/stdlib_sourcing_plan.md, Phase 1).
// The engine orders slot pointers through the facade's comparator
// (std.collections.engine_slot); the facade owns every value.
//
// Complexity contract: O(log n) push and pop, O(1) peek.

use std.option
use std.traits
use std.c_algorithms.defs
use std.c_algorithms.binary_heap

use std.collections.engine_slot.Slot
use std.collections.engine_slot.slot_compare

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

// The engine's BINARY_HEAP_TYPE_MIN / BINARY_HEAP_TYPE_MAX (std.c_algorithms.defs),
// spelled here until #1136 lets a nested module import a corpus global.
const HEAP_TYPE_MIN: c_uint = 0
const HEAP_TYPE_MAX: c_uint = 1

/// A max-heap by default (`pop` yields the greatest value); `new_min()`
/// builds the min-heap. `T: Ord` orders through `cmp` (D41). `peek`
/// observes, `pop` transfers (D27).
pub type BinaryHeap[T] { heap: *mut _BinaryHeap }

fn binary_heap_engine(max: bool) -> *mut _BinaryHeap:
    let heap_type = if max: HEAP_TYPE_MAX else: HEAP_TYPE_MIN
    let heap = binary_heap_new(heap_type as i32, slot_compare)
    assert(heap as i64 != 0)
    heap

pub fn BinaryHeap.new[T: Ord]() -> BinaryHeap[T]:
    BinaryHeap { heap: binary_heap_engine(true) }

pub fn BinaryHeap.new_min[T: Ord]() -> BinaryHeap[T]:
    BinaryHeap { heap: binary_heap_engine(false) }

impl[T: Ord] BinaryHeap[T]:
    fn comparator() -> fn(*const u8, *const u8) -> i32:
        (a, b) =>
            let left = unsafe { &(*(a as *const Slot[T])).value }
            let right = unsafe { &(*(b as *const Slot[T])).value }
            if left < right: -1 else if left > right: 1 else: 0

    pub fn len() -> i32: unsafe { binary_heap_num_entries(self.heap) } as i32
    pub fn is_empty() -> bool: self.len() == 0

    pub mut fn push(value: T) -> Unit:
        let slot = unsafe { with_alloc(sizeof[Slot[T]]() as i64) } as *mut Slot[T]
        unsafe { *slot = Slot { compare: self.comparator(), value: value } }
        assert(unsafe { binary_heap_insert(self.heap, slot as *mut c_void) } != 0)

    /// Transfers the top value out, or `None` when empty.
    pub mut fn pop() -> Option[T]:
        var slot = unsafe { binary_heap_pop(self.heap) } as *mut Slot[T]
        if slot as i64 == 0: return None
        let value: T = unsafe { move slot.value }
        unsafe { with_free(slot as *mut u8) }
        Some(value)

    /// Observes the top value, or `None` when empty.
    pub fn peek() -> Option[&T]:
        if self.len() == 0: return None
        let slot = unsafe { *(*self.heap).values } as *const Slot[T]
        Some(unsafe { &(*slot).value })

impl[T] Drop for BinaryHeap[T]:
    move fn drop():
        // The engine's value array is its own; walk it and release every
        // slot before the engine frees the array.
        let count = unsafe { binary_heap_num_entries(self.heap) } as i32
        for index in 0..count:
            var slot = unsafe { (*self.heap).values[index] } as *mut Slot[T]
            let value: T = unsafe { move slot.value }
            drop(value)
            unsafe { with_free(slot as *mut u8) }
        unsafe { binary_heap_free(self.heap) }
