//! expect-stdout: 5 20 5
//! expect-stdout: 10

// An index is a value wherever its place stands. In an assignment target,
// `xs[if c: 1 else: 2] = v` typed the `if` as a statement (Unit) and was
// refused, on main too; the migrator emits exactly this for C's
// `tree[cond ? a : b].freq++` (zlib's deflate and trees).
type Cell { n: i32 }

fn main:
    var xs = [10, 20, 30]
    let c = true
    xs[if c: 1 else: 2] = 5
    var cells = [Cell { n: 0 }, Cell { n: 0 }]
    cells[if c: 0 else: 1].n = 5
    print(f"{xs[1]} {xs[0] + 10} {cells[0].n}")
    print(xs[if c: 0 else: 2])
