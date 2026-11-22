//! expect-stdout: 3 6 4 12
// §4.3a (#2121): the length of `[T; N]` is an integer literal or a constant
// expression: a `const`, arithmetic over consts, a const of another module.
const N: i32 = 3
const ROWS = 2

type Grid { cells: [i32; N * ROWS] }

fn zeros() -> [i32; N]: [0; N]

fn sum(xs: [i32; N + 1]): xs[0] + xs[1] + xs[2] + xs[3]

fn main:
    var xs: [i32; N] = zeros()
    xs[2] = 7
    let grid = Grid { cells: [1; N * ROWS] }
    const LOCAL = 4
    let ys: [i32; LOCAL] = [3; LOCAL]
    print(f"{xs.len()} {grid.cells.len()} {ys.len()} {sum(ys)}")
