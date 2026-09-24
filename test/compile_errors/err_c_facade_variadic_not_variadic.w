//! expect-check-fail: fn 'note_id': 'variadic param …' describes a variadic C function, and 'note_id' is not variadic (§16.2b.5, §16.2b.13)

// D66 (spec §16.2b.5): the clause describes a variadic declaration.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    fn note_id
        variadic param 1 selected by param 0:
            case UL_SETFSIZE: c_long

fn main:
    print("unreached")
