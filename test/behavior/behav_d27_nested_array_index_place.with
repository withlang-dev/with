//! expect-exit: 0

// D27 E1/E2: each nested read has exact type &T, while the write path remains
// the physical IndexPlace chain. Do not emit dereferences between array GEPs.
fn main:
    var grid: [2][3][4]u8 = [[[0 as u8; 4]; 3]; 2]
    grid[1][2][3] = 9 as u8
    let row = grid[1][2]
    assert(row[3] == 9)
    assert(grid[1][2][3] == 9)
