// T6-loop + T23: `for` is NOT built by BorrowCfg.build_expr (:28: "Match
// and for are not yet built" -> default Expr arm :183-184), yet Sema's
// expr_uses_symbol recurses through for-loops (BorrowCfg.w:13-15), so the
// borrow rule must still fire here. Expect live-view check failure.
type Pair {
    a: i32,
    b: i32,
}

fn main:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    for i in 0..3:
        p.a = p.a + i
    assert(*a_view == 1)
