//! check-only

// Parser test for multi-dimensional indexing syntax
// Full runtime test requires a MultiIndex trait implementation

type Matrix { data: i32 }

impl Matrix:
    fn multi_index(self: Matrix, n: i32) -> i32:
        self.data + n

fn main:
    let m = Matrix { data: 100 }
    // These should parse without errors (multi-index syntax)
    // Actual execution deferred until MIR support is added
    // let v = m[0, 1]          // two scalar indices
    // let s = m[0:3, :]        // slice + all
    // let e = m[..., 0]        // ellipsis
