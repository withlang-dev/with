//! expect-stdout: ab ab ab 2
//! expect-stdout: 2 1 6 2

// #2578 (D27): an element place (`xs[i]`) is the element itself; Sema types
// the expression as a view, and the lowering must not read it through a
// reference. A slice, `rest()`, `first()` and a `for` over such a place.
fn main:
    let parts: List[str] = ["ab:cd"]
    let arr: [str; 1] = ["ab:cd"]
    let sl: []str = parts[..]
    let v: List[List[i32]] = [[1, 2, 3]]
    print(f"{parts[0][..2]} {arr[0][..2]} {sl[0][..2]} {v[0][1..].len()}")
    let base = [1, 2, 3]
    let seqs: List[[]i32] = [base[..]]
    let arrs: [[i32; 3]; 1] = [[4, 5, 6]]
    var total = 0
    for x in seqs[0]: total = total + x
    print(f"{seqs[0].rest().len()} {seqs[0].first() ?? 0} {total} {arrs[0].rest().len()}")
