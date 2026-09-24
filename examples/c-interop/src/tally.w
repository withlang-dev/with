// A vendored C library: structs by value, a C global, a callback, and C that
// calls With. The contracts are in src/facades/tally.w; three of them are ones
// the facade language cannot state yet (a buffer with an element count, a
// callback on a function that receives no resource), and those three calls
// stay raw, here, until the clauses land. Everything `pub` is safe.
use c_import("tally.h", link: "tally")
use facades.tally

// C takes a pointer and a count. An empty slice has no first element to point at.
fn data(values: []i32) -> *const i32: if values.len() == 0: null else: &raw const values[0]

// TallyRange is C's struct, and With's: it is built, passed and returned by
// value with no declaration here.
pub fn range_of(values: []i32) -> TallyRange:
    unsafe { tally_range(data(values), values.len() as i32) }

// A by-value call is a lend (src/facades/tally.w): no `unsafe`.
pub fn widened(range: TallyRange, by: i32) -> TallyRange: tally_widen(range, by)

// A C global, read like any other.
pub fn calls -> i32: tally_calls

// C calls this once per value. It is an ordinary With function: a named
// function (or a closure that captures nothing) is a C function pointer. C
// has nowhere to keep a closure's captures, so state travels the way C
// libraries carry it: through the `void *` the library hands back.
fn collect(context: *mut c_void, value: i32):
    let seen = context as *mut Vec[i32]
    unsafe { (*seen).push(value) }

pub fn visited(values: []i32) -> Vec[i32]:
    var seen: Vec[i32] = Vec.new()
    unsafe { tally_each(data(values), values.len() as i32, collect, &raw mut seen) }
    seen

// The other direction. `@[c_export]` gives a With function a C name and the C
// ABI; tally.c calls it as `c_interop_score`, knowing nothing about With.
// `with emit-c-header src/tally.w` writes the prototype for a C project.
@[c_export("c_interop_score")]
fn score(value: i32) -> i32: if value < 0: 0 else: value * value

pub fn total(values: []i32) -> i32:
    unsafe { tally_total(data(values), values.len() as i32) }
