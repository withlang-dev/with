pub type Cell[T] {
    value: T,
}

pub fn Cell.wrap(value: T) -> Self:
    Self { value }

pub fn Cell.get(self: Cell[T]) -> T:
    self.value

pub fn cell_sum(cells: Vec[Cell[i32]]) -> i32:
    var total = 0
    var i = 0
    while i < cells.len():
        total = total + cells[i].get()
        i = i + 1
    total
