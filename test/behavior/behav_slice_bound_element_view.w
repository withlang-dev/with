//! expect-stdout: llo
//! expect-stdout: 3 4
//! expect-stdout: 2

// D22 §6.2: a slice bound is an owned demand for its integer. A bound that
// names an element (`let at = cuts[0]` binds the view, D27) is copied
// there, as a range's bound is; it reached codegen as the element's
// address ("Both operands to a binary operator are not of the same type").
fn main:
    let s = "hello world"
    var cuts: Vec[i64] = Vec.new()
    cuts.push(2)
    cuts.push(4)
    let at = cuts[0]
    print(s[at..at + 3])
    let v: Vec[i32] = [1, 2, 3, 4, 5]
    let tail = v[at..cuts[1]]
    print(f"{tail[0]} {tail[1]}")
    let a = [7, 8, 9, 10]
    print(a[..at].len())
