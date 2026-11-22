//! expect-error: requires a mutable receiver

// #2095: an element of a vector the function only borrows is a read-only
// view; `rows[i].push(x)` needs a vector the program may mutate.

fn poke(rows: &List[List[i32]]):
    rows[0].push(9)

fn main:
    var rows: List[List[i32]] = List.new()
    rows.push(List.new())
    poke(rows)
