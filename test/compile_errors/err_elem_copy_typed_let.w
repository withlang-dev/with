//! expect-error: type mismatch in binding

// D27: a binding names what's there; an annotation demands what it says.
// A typed binding is an owned demand (D22 §6.2) and cannot be satisfied by
// copying a Drop-bearing element out of a List. (The unannotated form
// `let t = items.get(0)` binds the view and stays legal.)

use std.builtins.int_to_string
type Thing { vals: List[i32] }

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    let t: Thing = items[0]
    print(int_to_string(t.vals.len()))
