// T6 negative control: last use of the view precedes the mutation, so
// Sema.expire_dead_borrows_in_block (NLL) expires the borrow; must pass.
type Pair {
    a: i32,
    b: i32,
}

fn main:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    assert(*a_view == 1)
    p.a = 10
    assert(p.a == 10)
