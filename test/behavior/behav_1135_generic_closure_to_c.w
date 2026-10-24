//! expect-stdout: ok

// #1135: a non-capturing closure written inside a generic function and
// coerced to `extern "C" fn` is a plain C-ABI entry when C calls it back
// (the migrated c-algorithms sorted array orders through it). It once ran
// the closure thunk instead and crashed on the first comparison. The
// sample fixes `T`: an `isize` sample over `i32` values reads eight bytes
// and orders garbage, which is the program's mistake, not the compiler's.

use std.engines.c_algorithms.defs
use std.engines.c_algorithms.sortedarray

fn comparator[T: Ord](sample: &T) -> unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int:
    (a, b) => (unsafe { *(a as *const T) as &T }).cmp(*(unsafe { *(b as *const T) as &T })) as c_int

fn main:
    let seed: i32 = 0
    let array = sortedarray_new(0 as c_uint, comparator(&seed))
    // The values live in this array for the engine's lifetime; the engine
    // holds their addresses.
    var values: [i32; 3] = [5, 1, 3]
    for i in 0..3: assert(unsafe { sortedarray_insert(array, (&raw const values[i]) as *mut c_void) } != 0)
    var sorted: List[i32] = []
    for i in 0..3: sorted.push(unsafe { *(sortedarray_get(array, i as c_uint) as *const i32) })
    unsafe { sortedarray_free(array) }
    assert(sorted == [1, 3, 5], f"sorted through the generic comparator: {sorted:?}")
    print("ok")
