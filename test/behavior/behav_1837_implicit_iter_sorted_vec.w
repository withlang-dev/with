//! expect-stdout: 1 3 7
//! expect-stdout: 3

// §13.5 (#1837): "When it does not implement `Iter[T]` but has an `.iter()`
// method that returns an `Iter[T]`, the compiler inserts `.iter()`
// automatically." SortedVec is a std collection with no `next()` and an
// `iter()` returning SortedVecIter[T]; the bare spelling is the spelled one.
use std.collections.sorted_vec

fn main:
    var s: SortedVec[i32] = SortedVec.new()
    s.insert(7)
    s.insert(1)
    s.insert(3)
    var out = ""
    for x in s:
        out = if out.len() == 0: f"{x}" else: out ++ f" {x}"
    print(out)
    // The loop borrowed the collection: it is still whole afterwards.
    print(f"{s.len()}")
