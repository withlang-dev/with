//! expect-stdout: 7 3

// A Copy value read through a raw dereference of a local is an independent
// value, not a view of that local. Assigning it to a global recorded the local
// as the global's view origin (the assignment's value expression contains
// `&raw const a`), and when `a` left scope the global was poisoned: reading it
// in another function failed with "view `g_id` may originate from `a`, which
// no longer lives here (§21.1 Rule 6)". Only a binding whose type can hold a
// view — a reference, an ephemeral value, a Drop value — can be poisoned.
// (The migrated pcre2 corpus carried a path exemption for this; it is gone.)
type S { adler: u64 = 0, pad: u64 = 0 }
impl Copy for S
var g_id: u64 = 0

unsafe fn plain -> i32:
    var a: S = S { adler: 7 }
    g_id = (*(&raw const a as *const S)).adler
    0

fn reads -> u64: g_id

fn main:
    unsafe { plain() }
    let first = reads()
    var b: S = S { adler: 3 }
    let local: u64 = unsafe { (*(&raw const b as *const S)).adler }
    print(f"{first} {local}")
