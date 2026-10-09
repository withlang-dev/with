//! expect-error: type mismatch in assignment

// D22 §13.6 / D27: assignment into an owned place is an owned demand and
// the exact &Thing element view cannot satisfy it because Thing is not Copy.

use std.builtins.int_to_string
type Thing { vals: List[i32] }

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    var slot = Thing { vals: List.new() }
    slot = items[0]
    print(int_to_string(slot.vals.len()))
