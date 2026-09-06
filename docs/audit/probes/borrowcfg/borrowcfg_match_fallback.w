// T23: match/fallthrough. BorrowCfg.build_expr (:183-184) has NO match/for
// arm, so a match subtree silently collapses to one Expr node (structural
// fallback). This probe shows the fallback is unobservable/harmless: Sema
// still enforces the borrow rule across match arms. Expect check failure
// with a live-view diagnostic.
type Pair {
    a: i32,
    b: i32,
}

fn main:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    match p.b:
        2 => p.a = 10
        _ => p.a = 20
    assert(*a_view == 1)
