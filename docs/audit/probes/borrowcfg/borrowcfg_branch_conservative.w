// T6-conservative: view used ONLY in then-branch; mutation in else-branch;
// NO use after the if. Borrow is dead on the else path, but Sema scoped
// expiry keeps it alive to the outer block (safe, conservative reject).
// Expect check failure per docs/completed/p6-view-liveness-design.md §7.
type Pair {
    a: i32,
    b: i32,
}

fn branch(p: Pair, flag: bool) -> i32:
    var q = p
    let a_view = &q.a
    if flag:
        return *a_view
    q.a = 10
    q.a
