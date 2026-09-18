// T5 variant: move the WHOLE place (not a field) while a view into a
// sub-place is live and used after. Expect conflict error if move/borrow
// interaction is enforced on whole-place moves.
type Pair {
    a: i32,
    b: i32,
}

fn main:
    var p = Pair { a: 1, b: 2 }
    let v = &p.a
    let q = move p
    assert(*v + q.b == 3)
