//! expect-check-fail: type does not support index assignment (no IndexPlace impl)

// #3046 (§11.7): `IndexGet[I, V]` is the read-only subscript trait; only an
// `IndexPlace` impl makes `expr[index]` a writable place.

type Matrix { data: List[f64], cols: usize }

impl IndexGet[(usize, usize), f64] for Matrix:
    fn get(self: &Self, rc: (usize, usize)) -> f64:
        let (r, c) = rc
        self.data[(r * self.cols + c) as isize]

fn main:
    var m = Matrix { data: [1.0, 2.0, 3.0, 4.0], cols: 2 }
    m[(1usize, 0usize)] = 9.0
    print(m[(1usize, 0usize)] as i32)
