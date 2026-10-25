//! expect-stdout: 20 30 5
// #2554: an importer that declares `extern fn c2554_bump` (its view of the
// C symbol) next to a module whose `@[c_export("c2554_bump")]` defines it.
// The definition was dropped by the declaration, and the link failed with
// `undefined symbol: _c2554_bump`.
use behav_2554_c_export_owner

extern fn c2554_bump(x: i64) -> i64

fn main:
    let a = unsafe { c2554_bump(2) }
    let b = unsafe { c2554_bump(3) }
    print(f"{a} {b} {c2554_total()}")
