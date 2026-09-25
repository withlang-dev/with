// A vendored C library: structs by value, a C global, a callback, and C that
// calls With. The contracts in src/facades/tally.w pair element buffers and
// counts and keep callback userdata typed. Application code stays safe.
use c_import("tally.h", link: "tally")
use facades.tally

// TallyRange is C's struct, and With's: it is built, passed and returned by
// value with no declaration here.
pub fn range_of(values: []i32) -> TallyRange:
    tally_range(values)

// A by-value call is a lend (src/facades/tally.w): no `unsafe`.
pub fn widened(range: TallyRange, by: i32) -> TallyRange: tally_widen(range, by)

// A C global, read like any other.
pub fn calls -> i32: tally_calls

// C calls this once per value. Its userdata borrows a With callable whose
// captures remain tracked; it never casts a raw pointer to a mutable Vec.
fn collect(visit: &fn(i32) -> Unit, value: i32): visit(value)

pub fn visited(values: []i32) -> Vec[i32]:
    var seen: Vec[i32] = Vec.new()
    tally_each(values, collect, value => seen.push(value))
    seen

// The other direction. `@[c_export]` gives a With function a C name and the C
// ABI; tally.c calls it as `c_interop_score`, knowing nothing about With.
// `with emit-c-header src/tally.w` writes the prototype for a C project.
@[c_export("c_interop_score")]
fn score(value: i32) -> i32: if value < 0: 0 else: value * value

pub fn total(values: []i32) -> i32:
    tally_total(values)
