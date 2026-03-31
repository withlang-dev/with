//! args: --dump-mir
//! expect-check-stdout: mir module functions=

type Entry {
    name: str,
    values: Vec[i32],
}

fn score(entries: Vec[Entry], lookup: HashMap[str, i32]) -> i32:
    var total = 0
    var i = 0
    while i < entries.len():
        let entry = entries[i]
        if entry.name.len() > 0 and entry.name.contains("a"):
            total = total + entry.values.len() as i32
        let parts = entry.name.split(",")
        if parts.len() > 0 and lookup.contains(entry.name):
            total = total + lookup.len() as i32
        let maybe = lookup.get(entry.name)
        if maybe.is_some():
            total = total + maybe.unwrap()
        i = i + 1
    total

fn main:
    let entries: Vec[Entry] = Vec.new()
    let lookup: HashMap[str, i32] = HashMap.new()
    let _ = score(entries, lookup)
