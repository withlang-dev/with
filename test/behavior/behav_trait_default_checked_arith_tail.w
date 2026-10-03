//! expect-stdout: 3 6

// A default trait method is emitted by its own MIR loop (CodegenTraits).
// Checked arithmetic ends its statement in a block of its own (`arith.ok`),
// and that loop placed the MIR terminator only when the MIR block's first
// LLVM block was unterminated, so `self.size() + 1` left `arith.ok` with no
// terminator: "Basic Block in function 'P.total' does not have terminator!".

trait Sized2:
    fn size(self: &Self) -> i32
    fn total(self: &Self) -> i32: self.size() + 1
    fn twice(self: &Self) -> i32: self.size() * 2 + self.total() - 1

type P { n: i32 }

impl Sized2 for P:
    fn size -> i32: self.n

fn main:
    let p = P { n: 2 }
    print(f"{p.total()} {p.twice()}")
