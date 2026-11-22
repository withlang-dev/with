// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: compile-and-run
// expected-diagnostic: none; the condition is the view's final use

use std.collections.HashMap
type NllConditionMap {
    values: HashMap[i32, i32],
}

impl NllConditionMap:
    mut fn put(key: i32, value: i32): self.values.insert(key, value)

    mut fn copy_then_mutate(key: i32):
        let found = self.values.get(key)
        if found.is_some() and found.unwrap() != 0: self.put(2, 3)

fn main:
    var values = NllConditionMap { values: HashMap.new() }
    values.put(1, 7)
    values.copy_then_mutate(1)
