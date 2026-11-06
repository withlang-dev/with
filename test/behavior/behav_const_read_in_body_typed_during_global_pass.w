//! expect-stdout: 1024 19 7
// A body checked inside the global-initializer pass reads an untyped
// `const` declared below the global: the const's slot is typed by its
// own initializer, so that initializer is checked first (as a later
// global's is). The chain: `H`'s initializer names `fill` as a value, so
// `fill`'s body is typed from the use; its `.store(7)` call pulls every
// `store` whose summary a caller reads (`Arena.store` stores a view of
// its `&str` parameter, #1783) in before it; `Arena.store` reads `PAGE`
// and `BIG` while the pass has not reached them yet. It typed the read
// `<error>` with no diagnostic, and MIR refused the `if` as `Never`.

type Arena { n: isize }

impl Arena:
    mut fn store(s: &str) -> isize:
        let size = if PAGE + s.len() > BIG: PAGE + s.len() else: BIG
        self.n = size
        size

type Cell { v: isize }

impl Cell:
    mut fn store(value: isize): self.v = value

fn fill(c: Cell):
    var filled = c
    filled.store(7)
    filled

type Holder { f: fn(Cell) -> Cell }

let H = Holder { f: fill }

const PAGE = 16
const BIG = 1024

fn main:
    var a = Arena { n: 0 }
    let small = a.store("abc")
    let big = a.store("0123456789abcdefghi" ++ "x" ++ "y" ++ "z")
    let c = (H.f)(Cell { v: 0 })
    print(f"{small} {big - 1005} {c.v}")
