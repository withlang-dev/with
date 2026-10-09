//! expect-stdout: 6 2 3 15 6
//! expect-stdout: 2 7 0 3
//! expect-stdout: 30

// D119 Amendment 1: `[T; 2, 3]` lists a nested fixed array's dimensions in
// index order and is `[[T; 3]; 2]`, the same type: a row is `[T; 3]`, `len()`
// is the outer dimension. A fill has its type's shape; undemanded it is a
// List of fixed rows (D113), demanded it is the fixed array.
fn row_sum(r: [i32; 3]) -> i32: r[0] + r[1] + r[2]
fn takes_nested(m: [[i32; 3]; 2]) -> i32: m[1][2]

fn main:
    let fixed: [i32; 2, 3] = [0; 2, 3]
    let m: [i32; 2, 3] = [[1, 2, 3], [4, 5, 6]]
    print(f"{m[1][2]} {m.len()} {m[0].len()} {row_sum(m[1])} {takes_nested(m)}")
    var grid = [7; 2, 3]
    let before = grid.len()
    grid.push([1, 2, 3])
    print(f"{before} {grid[1][2]} {fixed[1][0]} {grid.len()}")
    let cube: [u8; 2, 2, 3] = [[[1, 2, 3], [4, 5, 6]], [[1, 1, 1], [2, 2, 2]]]
    var total = 0
    for plane in cube:
        for row in plane:
            for v in row: total = total + v as i32
    print(total)
