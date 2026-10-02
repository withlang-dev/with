//! expect-error: type mismatch in binding

// D27: a binding names what's there; an annotation demands what it says.
// A typed binding is an owned demand (D22 §6.2) and cannot be satisfied by
// copying a Drop-bearing element out of a Vec. (The unannotated form
// `let t = items.get(0)` binds the view and stays legal.)

use std.builtins.int_to_string
type Thing { vals: Vec[i32] }

fn main:
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: Vec.new() })
    let t: Thing = items[0]
    print(int_to_string(t.vals.len()))
