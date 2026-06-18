// Spec test: Section 7.1 - With Type-Based Guard Inference

use std.sync

fn test_scoped_type_binds_payload:
    let lock = Mutex[i64].new(42 as i64)
    let val = with lock.enter() as data:
        *data + 1
    assert(val == 43)

fn test_non_scoped_mut_binding_is_builder:
    let v = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
    assert(v.len() == 2)
