// T6+T23: branch-divergent use. Borrow used only in one branch, mutation
// after the if. BorrowCfg.w:22-24 documents branch-divergent uses as NOT
// covered (would need the CFG fleshed out); Sema scoped expiry keeps the
// borrow alive to the outer block (conservative). Record actual outcome.
type Pair {
    a: i32,
    b: i32,
}

fn main:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    if p.b == 2:
        assert(*a_view == 1)
    p.a = 10
    assert(p.a == 10)
