pub type Cell[T] {
    value: T,
}

pub fn Cell.wrap(value: T) -> Self:
    Self { value }

pub fn Cell.get(self: &Self) -> T:
    self.value

pub fn cell_sum(cells: List[Cell[i32]]) -> i32:
    var total: i32 = 0
    var i = 0
    while i < cells.len():
        total = total + cells[i].get()
        i = i + 1
    total
