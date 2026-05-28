//! expect-stdout: ok

use c_import("typedef struct Hidden288 Hidden288;\ntypedef struct Holder288 { Hidden288 *hidden; int value; } Holder288;\nint consume_holder288(Holder288 *holder);\n")

fn main:
    print("ok")
