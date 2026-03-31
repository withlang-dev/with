use issue59_queries.shared

pub fn method_score(state: State, lookup: HashMap[str, i32]) -> i32:
    var counter = Counter.new()
    var i = 0
    while i < state.entries.len():
        let entry = state.entries[i]
        counter = counter.bump(entry.values.len() as i32)
        if entry.name.starts_with("a"):
            counter = counter.bump(1)
        let maybe = lookup.get(entry.name)
        if maybe.is_some():
            counter = counter.bump(maybe.unwrap())
        i = i + 1
    counter.get()
