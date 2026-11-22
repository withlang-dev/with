//! expect-stdout: ok
// §16.4: a c_import union has the size of its largest member and reads back
// the last-written field.
use c_import("typedef union CVal { int i; double d; unsigned char bytes[8]; } CVal;\n")
fn main:
    var v = CVal { i: 42 }
    if v.i == 42 and sizeof[CVal]() == 8: print("ok")
    else: print("bad")
