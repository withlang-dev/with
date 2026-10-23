// std.algorithms — generic sequence algorithms over the migrated STC
// algorithm layer (docs/proposals/stdlib_sourcing_plan.md, Phase 3; the facade
// map's primary engine for sort and the searches). STC's `sort.h` is a
// template; the corpus's facade shapes unit instantiates it for the slot
// reference shape — `{comparator, pointer}` pairs ordered through the With
// comparator — and for the word shapes (`i64`, `u64`, `f64`), which sort
// in place with the engine's own `<`. Any other `T` is sorted through the
// references and then permuted once by bits (every element moves exactly
// once, D27: no second live value, no drop).
//
// Complexity contract: O(n log n) sort (quicksort; not stable — `sort_by`
// promises no order among equal elements), O(log n) binary search and
// bounds, O(n) reverse.

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use rt.rt_core

/// The slot reference the engine orders, laid out as the shapes unit's
/// `stc_slotref`: the C-ABI comparison the engine calls with the two
/// references, the element's address, and the With comparator that
/// comparison dispatches to. (#1135: a closure written in a generic
/// function cannot be handed to the engine; the trampoline is the one
/// C-ABI function.)
type SlotRef { cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> c_int], ptr: *const c_void, compare: *const fn(*const u8, *const u8) -> i32, env_pad: i64 }

unsafe fn slot_ref_compare(a: *const c_void, b: *const c_void) -> c_int:
    let left = a as *const SlotRef
    let right = b as *const SlotRef
    // D63: a callable is not Copy (nor always Clone); every reference points
    // at the one comparator the sort owns.
    let compare = &*((*left).compare)
    compare((*left).ptr as *const u8, (*right).ptr as *const u8) as c_int

// The element pointer only carries `T` (type arguments are never written
// at a call site).
fn ord_compare[T: Ord](elems: *const T) -> fn(*const u8, *const u8) -> i32:
    (a, b) =>
        let left = unsafe { &*(a as *const T) }
        let right = unsafe { &*(b as *const T) }
        if left < right: -1 else if left > right: 1 else: 0

fn by_compare[T](cmp: fn(&T, &T) -> i32) -> fn(*const u8, *const u8) -> i32:
    move (a, b) => cmp(unsafe { &*(a as *const T) }, unsafe { &*(b as *const T) })

/// Sorts `n` elements at `base` through `compare`: the slot references are
/// ordered by the engine, then the elements are laid out in that order by
/// one pass of byte moves through a scratch buffer.
unsafe fn sort_through_refs[T](base: *mut T, n: isize, compare: fn(*const u8, *const u8) -> i32):
    if n < 2: return
    let size = sizeof[T]() as i64
    let refs = with_alloc(n as i64 * sizeof[SlotRef]() as i64) as *mut SlotRef
    let compare_cell = &raw const compare
    for i in 0..n:
        refs[i] = SlotRef { cmp: Some(slot_ref_compare), ptr: (base as i64 + i as i64 * size) as *const c_void, compare: compare_cell, env_pad: 0 }
    stc_slotrefs_sort(refs as *mut stc_slotref, n as i64)
    let scratch = with_alloc(n as i64 * size)
    for i in 0..n:
        with_memcpy((scratch as i64 + i as i64 * size) as *mut u8, refs[i].ptr as *const u8, size)
    with_memcpy(base as *mut u8, scratch as *const u8, n as i64 * size)
    with_free(scratch)
    with_free(refs as *mut u8)

impl[T: Ord] List[T]:
    /// Sorts ascending by `Ord` (D41). The word shapes sort in place through
    /// the engine's own instantiation; everything else through references.
    pub mut fn sort():
        let n = self.len()
        if n < 2: return
        let base = self.ptr as *mut T
        comptime if T.name() == "i64":
            unsafe { stc_i64s_sort(base as *mut c_longlong, n as i64) }
        else if T.name() == "u64":
            unsafe { stc_u64s_sort(base as *mut c_ulonglong, n as i64) }
        else if T.name() == "f64":
            unsafe { stc_f64s_sort(base as *mut f64, n as i64) }
        else:
            unsafe { sort_through_refs(base, n, ord_compare(self.ptr)) }

    /// The index of an element equal to `value` in a sorted list, if any.
    pub fn binary_search(value: &T) -> Option[isize]:
        var lo: isize = 0
        var hi = self.len()
        while lo < hi:
            let mid = lo + (hi - lo) / 2
            if self[mid] < *value: lo = mid + 1
            else if *value < self[mid]: hi = mid
            else: return Some(mid)
        None

    /// The first index whose element is not less than `value` (the list
    /// sorted ascending); `len()` when none.
    pub fn lower_bound(value: &T) -> isize:
        var lo: isize = 0
        var hi = self.len()
        while lo < hi:
            let mid = lo + (hi - lo) / 2
            if self[mid] < *value: lo = mid + 1 else: hi = mid
        lo

    /// The first index whose element is greater than `value`; `len()` when
    /// none.
    pub fn upper_bound(value: &T) -> isize:
        var lo: isize = 0
        var hi = self.len()
        while lo < hi:
            let mid = lo + (hi - lo) / 2
            if *value < self[mid]: hi = mid else: lo = mid + 1
        lo

impl[T] List[T]:
    /// Sorts by `cmp` (negative: a before b). Not stable.
    pub mut fn sort_by(cmp: fn(&T, &T) -> i32):
        let n = self.len()
        if n < 2: return
        let base = self.ptr as *mut T
        unsafe { sort_through_refs(base, n, by_compare(cmp)) }

    /// Reverses the elements in place (every element moves once, by bits).
    pub mut fn reverse():
        let n = self.len()
        if n < 2: return
        let size = sizeof[T]() as i64
        let base = self.ptr as i64
        let tmp = with_alloc(size)
        var i: isize = 0
        var j = n - 1
        while i < j:
            let a = (base + i as i64 * size) as *mut u8
            let b = (base + j as i64 * size) as *mut u8
            with_memcpy(tmp, a as *const u8, size)
            with_memcpy(a, b as *const u8, size)
            with_memcpy(b, tmp as *const u8, size)
            i = i + 1
            j = j - 1
        with_free(tmp)



