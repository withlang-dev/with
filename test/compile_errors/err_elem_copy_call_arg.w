//! expect-error: wrong argument type in call to 'consume'

// D22 §13.6 / #715: a by-value parameter is an owned demand and cannot be
// satisfied by copying a Drop-bearing element out of a List. Under D27 E1 the
// element read types as &Thing, so the general call-arg check rejects it
// structurally before the interim #715 gate — the E3-target diagnostic,
// reached early.

use std.builtins.int_to_string
type Thing { vals: List[i32] }

fn consume(t: Thing) -> i64:
    t.vals.len()

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    print(int_to_string(consume(items[0])))
