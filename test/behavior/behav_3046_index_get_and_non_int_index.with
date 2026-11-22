//! expect-stdout: 3 2
//! expect-stdout: 5 7
//! expect-stdout: ok

// #3046 (§11.7): `expr[index]` dispatches to a user `IndexGet[I, V]` (read
// only) as well as `IndexPlace[I, V]`, and the index operand is checked
// against the impl's `I` — a tuple, a str — not forced to an integer.

type Matrix { data: List[f64], rows: usize, cols: usize }

impl IndexGet[(usize, usize), f64] for Matrix:
    fn get(self: &Self, rc: (usize, usize)) -> f64:
        let (r, c) = rc
        self.data[(r * self.cols + c) as isize]

type Counts { names: List[str], values: List[i32] }

impl Counts:
    fn slot_of(self: &Self, key: &str) -> isize:
        for i in 0..self.names.len():
            if self.names[i] == key: return i
        -1

impl IndexPlace[str, i32] for Counts:
    fn get(self: &Self, key: str) -> i32:
        let i = self.slot_of(key)
        if i < 0: 0 else: self.values[i]

    mut fn set(key: str, value: i32):
        let i = self.slot_of(key)
        if i < 0:
            self.names.push(key)
            self.values.push(value)
        else:
            self.values[i] = value

fn main:
    let m = Matrix { data: [1.0, 2.0, 3.0, 4.0], rows: 2, cols: 2 }
    print(f"{m[(1usize, 0usize)] as i32} {m[(0usize, 1usize)] as i32}")
    var c = Counts { names: List.new(), values: List.new() }
    c["a"] = 5
    c["b"] = 7
    print(f"{c["a"]} {c["b"]}")
    print("ok")
