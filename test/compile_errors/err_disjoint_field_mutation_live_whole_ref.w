//! expect-check-fail: cannot mutate `p` while read-only view `whole` is live

type Pair {
    a: i32,
    b: i32,
}

fn bad:
    var p = Pair { a: 1, b: 2 }
    let whole = &p
    p.a = 10
    assert((*whole).a == 1)
