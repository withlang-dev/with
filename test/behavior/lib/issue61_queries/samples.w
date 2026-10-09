use issue61_queries.generic
use issue61_queries.shared
use std.collections.HashMap

pub fn sample_state() -> State:
    let first_values: List[i32] = List.new()
    first_values.push(1)
    first_values.push(2)

    let second_values: List[i32] = List.new()
    second_values.push(3)

    let third_values: List[i32] = List.new()
    third_values.push(4)
    third_values.push(5)
    third_values.push(6)

    let entries: List[Entry] = List.new()
    entries.push(entry("alpha,one", move first_values))
    entries.push(entry("beta", move second_values))
    entries.push(entry("gamma", move third_values))

    state(move entries, Some("ally"), Ok(3))

pub fn sample_lookup() -> HashMap[str, i32]:
    let lookup = HashMap[str, i32].new()
    lookup.insert("alpha,one", 5)
    lookup.insert("beta", 7)
    lookup

pub fn sample_cells() -> List[Cell[i32]]:
    let cells: List[Cell[i32]] = List.new()
    cells.push(Cell.wrap(4))
    cells.push(Cell.wrap(6))
    cells
