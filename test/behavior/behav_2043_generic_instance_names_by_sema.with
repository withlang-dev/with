//! expect-stdout: 7 4294967295 -1

// #2043 (D65): a generic instance is named by Sema's identity, not by its
// arguments' LLVM types, under which `Cell[u32]` and `Cell[i32]` (both `i32`
// in LLVM) shared one name. Pins that the instances stay distinct and correct.
type Cell[T] {
    v: T,
}

impl[T] Cell[T]:
    fn get() -> T: self.v

fn main:
    let a = Cell { v: 7 as u8 }
    let b: Cell[u32] = Cell { v: 4294967295 as u32 }
    let c: Cell[i32] = Cell { v: -1 }
    print(f"{a.get()} {b.get()} {c.get()}")
