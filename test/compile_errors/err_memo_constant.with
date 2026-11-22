//! expect-error: constant `CELL` holds an `Interior`

// D172 (§19.1): a constant is an immutable static (D127), and the marker's
// contents change through a shared view.
use std.memo

const CELL: Interior[i32] = unsafe { Interior.new(5) }

fn main:
    print(unsafe { *CELL.ptr() })
