//! args: --dump-typed
//! expect-check-stdout: typed contextual-copy-adjustments=12
//! expect-check-stdout: bind view: &i32
//! expect-check-stdout: bind snapshot: i32
//! expect-check-stdout: exact=&i32 owned=i32 target=i32 post=identity
//! expect-check-stdout-not: bind view: i32
// The count includes the prelude: five of them are std.collections' D61 map
// formatter (debug_entry_order/debug_entry_before), where `order[a]`,
// `order[b]` and `scratch[k]` — `&i64` element places (D27) — meet an
// owned `i64` demand (an i64 parameter, an i64 element store) and take the
// same contextual Copy this fixture pins for `snapshot`. The rule did not
// move; the prelude gained five sites.


// SlotMap is D22's already-uniform keyed lookup control. This fixture asks only
// Sema questions; its ownership/drop behavior remains a Stage 5 gate.
use std.collections.SlotMap
fn main:
    var map: SlotMap[i32] = SlotMap.new()
    let handle = map.insert(88)
    let view = map.get(handle).unwrap()
    let snapshot: i32 = view
    assert(snapshot == 88)
