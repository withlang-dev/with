//! expect-error: type mismatch in struct literal field

// D22 §13.6 / D27: a struct-literal field is an owned demand and the exact
// &Thing element view cannot satisfy it because Thing is not Copy.

use std.builtins.int_to_string
type Thing { vals: List[i32] }
type Holder { t: Thing }

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    let h = Holder { t: items[0] }
    print(int_to_string(h.t.vals.len()))
