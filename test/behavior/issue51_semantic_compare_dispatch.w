type Entry {
    name: str,
    rank: i32,
}

type Wrap {
    items: Vec[Entry],
}

fn dup(s: str) -> str:
    s ++ ""

fn direct_str_eq(lhs: str, rhs: str) -> bool:
    lhs == rhs

fn projected_str_eq(wrap: &Wrap, idx: i32, expected: str) -> bool:
    wrap.items[idx].name == expected

fn entry_eq(lhs: Entry, rhs: Entry) -> bool:
    lhs == rhs

fn array_str_eq() -> bool:
    let lhs: [str; 1] = [dup("x")]
    let rhs: [str; 1] = ["x"]
    lhs == rhs

fn array_entry_eq() -> bool:
    let lhs: [Entry; 1] = [Entry { name: dup("x"), rank: 1 }]
    let rhs: [Entry; 1] = [Entry { name: "x", rank: 1 }]
    lhs == rhs

fn main:
    assert(direct_str_eq(dup("a"), "a"))
    let items: Vec[Entry] = Vec.new()
    items.push(Entry { name: dup("x"), rank: 1 })
    items.push(Entry { name: "y", rank: 2 })
    let wrap = Wrap { items }
    assert(projected_str_eq(wrap, 0, "x"))
    assert(not projected_str_eq(wrap, 1, "x"))
    assert(entry_eq(Entry { name: dup("x"), rank: 1 }, Entry { name: "x", rank: 1 }))
    assert(array_str_eq())
    assert(array_entry_eq())
