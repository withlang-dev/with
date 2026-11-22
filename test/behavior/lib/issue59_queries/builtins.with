use issue59_queries.shared
use std.collections.HashMap

pub fn builtin_score(state_in: State, lookup: HashMap[str, i32]) -> i32:
    var state = move state_in
    var total = state.tags.len() as i32
    if state.alias.is_some():
        total = total + (move state.alias).unwrap().len() as i32
    total = total + (move state.bonus).unwrap()

    var i = 0
    while i < state.entries.len():
        let entry = &state.entries[i]
        if entry.name.len() > 0 and entry.name.contains("a"):
            total = total + entry.values.len() as i32
        let parts = entry.name.split(",")
        if parts.len() > 1 and lookup.contains(entry.name):
            total = total + lookup.len() as i32
        let maybe = lookup.get(entry.name)
        if maybe.is_some():
            total = total + maybe.unwrap()
        i = i + 1
    total
