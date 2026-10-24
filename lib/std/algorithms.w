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
// promises no order among equal elements), O(n log n) stable sort, O(log n)
// binary search and bounds, O(n) reverse and shuffle.
//
// `stable_sort` was evaluated against upstream separately (the facade map's
// row): STC's sort is a quicksort with an insertion-sort tail and promises
// no order among equal elements, so the stable sort is a merge sort over
// the same reference layout, written here (the sourcing rule: a small,
// stable primitive is owned). `shuffle` is a Fisher–Yates over std.random
// (the With RNG, not the engine's `c_shuffle_array` macro and its own
// generator). `find`, `position`, `index_of` and `contains` are the
// language's iterator adapters, not facades.

use std.option
use std.traits
use std.engines.stc.defs
use std.engines.stc.facade_shapes
use std.random.range_isize
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

/// Lays the `n` elements at `base` out in the order of `order` (element
/// addresses) by one pass of byte moves through a scratch buffer.
unsafe fn permute_by_addresses(base: *mut u8, n: isize, size: i64, order: *const i64):
    let scratch = with_alloc(n as i64 * size)
    for i in 0..n:
        with_memcpy((scratch as i64 + i as i64 * size) as *mut u8, order[i] as *const u8, size)
    with_memcpy(base, scratch as *const u8, n as i64 * size)
    with_free(scratch)

/// Stable: a bottom-up merge sort of the element addresses through
/// `compare` (equal elements keep their input order), then one permutation
/// of the elements by bits.
unsafe fn stable_sort_through_refs[T](base: *mut T, n: isize, compare: fn(*const u8, *const u8) -> i32):
    if n < 2: return
    let size = sizeof[T]() as i64
    var source = with_alloc(n as i64 * 8) as *mut i64
    var target = with_alloc(n as i64 * 8) as *mut i64
    for i in 0..n: source[i] = base as i64 + i as i64 * size
    var width: isize = 1
    while width < n:
        var lo: isize = 0
        while lo < n:
            let mid = if lo + width < n: lo + width else: n
            let hi = if lo + width * 2 < n: lo + width * 2 else: n
            var i = lo
            var j = mid
            var k = lo
            while i < mid and j < hi:
                // The right run's element goes first only when strictly less.
                if compare(source[j] as *const u8, source[i] as *const u8) < 0:
                    target[k] = source[j]
                    j = j + 1
                else:
                    target[k] = source[i]
                    i = i + 1
                k = k + 1
            while i < mid:
                target[k] = source[i]
                i = i + 1
                k = k + 1
            while j < hi:
                target[k] = source[j]
                j = j + 1
                k = k + 1
            lo = hi
        let swapped = source
        source = target
        target = swapped
        width = width * 2
    permute_by_addresses(base as *mut u8, n, size, source)
    with_free(source as *mut u8)
    with_free(target as *mut u8)

impl[T: Ord] List[T]:
    /// Sorts ascending by `Ord`, keeping equal elements in their input
    /// order (merge sort; see the module note).
    pub mut fn stable_sort():
        let n = self.len()
        if n < 2: return
        unsafe { stable_sort_through_refs(self.ptr as *mut T, n, ord_compare(self.ptr)) }

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

    /// Sorts by `cmp`, keeping elements `cmp` calls equal in their input
    /// order.
    pub mut fn stable_sort_by(cmp: fn(&T, &T) -> i32):
        let n = self.len()
        if n < 2: return
        unsafe { stable_sort_through_refs(self.ptr as *mut T, n, by_compare(cmp)) }

    /// Shuffles the elements in place, uniformly, drawing from std.random
    /// (seed it for a reproducible order); every element moves by bits.
    pub mut fn shuffle():
        let n = self.len()
        if n < 2: return
        let size = sizeof[T]() as i64
        let base = self.ptr as i64
        let tmp = with_alloc(size)
        var i = n - 1
        while i > 0:
            let j = range_isize(0, i + 1)
            if j != i:
                let a = (base + i as i64 * size) as *mut u8
                let b = (base + j as i64 * size) as *mut u8
                with_memcpy(tmp, a as *const u8, size)
                with_memcpy(a, b as *const u8, size)
                with_memcpy(b, tmp as *const u8, size)
            i = i - 1
        with_free(tmp)

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



