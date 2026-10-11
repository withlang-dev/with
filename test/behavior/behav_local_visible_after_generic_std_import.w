//! expect-stdout: ok

// #747: generic instantiation of a std import (Box.new) saved
// current_module_path as a VIEW of the field; the overwrite in
// update_fn_source_context dropped the viewed value and the restore
// re-assigned from the dangling view, leaving Sema stuck in the std
// module — every LOCAL symbol then reported "not visible from this
// module". The save must move the field out (site-2005 idiom).
use std.box.Box

fn take_box(x: Box[i32]):
    let sink = x

fn main:
    let b: Box[i32] = Box.new(41)
    take_box(b)
    print("ok")
