//! expect-stdout: ok

use c_import("typedef struct Hidden288 Hidden288;\nstruct Hidden288 { int value; };\ntypedef struct Holder288 { Hidden288 *hidden; int value; } Holder288;\nint consume_holder288(Holder288 *holder);\n")

fn main:
    var hidden = Hidden288 { value: 41 }
    let holder = Holder288 { hidden: &raw mut hidden, value: 1 }
    assert(holder.value == 1)
    assert(unsafe { holder.hidden.value } == 41)
    print("ok")
