// T6 fire: mutation while a view into the same place is live must fail.
// Enforcement lives in Sema (borrow table + scoped expiry), NOT BorrowCfg.
type Pair {
    a: i32,
    b: i32,
}

fn main:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    p.a = 10
    assert(*a_view == 1)
