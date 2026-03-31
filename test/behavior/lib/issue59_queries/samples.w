use issue59_queries.generic
use issue59_queries.shared

pub fn sample_state() -> State:
    let first_values: Vec[i32] = Vec.new()
    first_values.push(1)
    first_values.push(2)

    let second_values: Vec[i32] = Vec.new()
    second_values.push(3)

    let entries: Vec[Entry] = Vec.new()
    entries.push(entry("alpha,one", first_values))
    entries.push(entry("beta", second_values))

    let tags: Vec[str] = Vec.new()
    tags.push("tag0")

    state(entries, tags, Some("ally"), Ok(3))

pub fn sample_lookup() -> HashMap[str, i32]:
    let lookup = HashMap[str, i32].new()
    lookup.insert("alpha,one", 5)
    lookup.insert("beta", 7)
    lookup

pub fn sample_cells() -> Vec[Cell[i32]]:
    let cells: Vec[Cell[i32]] = Vec.new()
    cells.push(Cell.wrap(4))
    cells.push(Cell.wrap(6))
    cells
