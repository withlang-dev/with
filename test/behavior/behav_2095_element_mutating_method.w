//! expect-stdout: 2 7 8
//! expect-stdout: 1 5
//! expect-stdout: 0
//! expect-stdout: grid 3 2
//! expect-stdout: ok

// #2095, D27: `xs[i]` denotes the element place, so a mutating method called
// on it mutates the element where it is — for a vector of vectors as for a
// vector of structs. The element reads as a view, which is not a read-only
// receiver when the vector it indexes is one the program may mutate.

type Grid { rows: List[List[i32]] }

impl Grid:
    mut fn add(i: i32, x: i32): self.rows[i].push(x)
    mut fn clear_row(i: i32): self.rows[i].clear()

fn main:
    var rows: List[List[i32]] = List.new()
    rows.push(List.new())
    rows.push(List.new())
    rows[0].push(7)
    rows[0].push(8)
    rows[1].push(5)
    print(f"{rows[0].len()} {rows[0][0]} {rows[0][1]}")
    print(f"{rows[1].len()} {rows[1][0]}")
    let _last = rows[1].pop()
    print(f"{rows[1].len()}")
    var grid = Grid { rows }
    grid.add(0, 9)
    grid.add(1, 1)
    grid.add(1, 2)
    grid.clear_row(1)
    grid.add(1, 3)
    grid.add(1, 4)
    print(f"grid {grid.rows[0].len()} {grid.rows[1].len()}")
    print("ok")
