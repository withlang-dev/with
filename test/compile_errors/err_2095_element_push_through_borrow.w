//! expect-error: requires a mutable receiver

// #2095: an element of a vector the function only borrows is a read-only
// view; `rows[i].push(x)` needs a vector the program may mutate.

fn poke(rows: &Vec[Vec[i32]]):
    rows[0].push(9)

fn main:
    var rows: Vec[Vec[i32]] = Vec.new()
    rows.push(Vec.new())
    poke(rows)
