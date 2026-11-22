//! expect-stdout: 6 par 2 3 7 4 5
//! expect-stdout: ok
// §16.2b.15: `use contracts.<name>` and a `c_import` of the library's
// header are two routes to one library, and both see the same types,
// functions, constants and globals (Eric, 2026-11-21, #3521). Through the
// contract route only the modeled resource was visible: a caller could not
// write the constant its own API needs.
use contracts.parity

fn main:
    let mode: par_mode = PAR_B
    let p = par_point { x: 1, y: 2 }
    let id: par_id = 7
    let h = Handle.open(1).unwrap()
    print(f"{PAR_LEVEL} {PAR_NAME} {mode as i32} {p.x + p.y} {id} {unsafe { par_static }} {par_plain(4)}")
    print("ok")
