use std.builtins.print_i32

type Cell {
    value: i32,
}

impl Cell:
    fn read(self: &Cell) -> i32: self.value

fn main:
    let cell = Cell { value: 7 }
    print_i32(cell.read())
