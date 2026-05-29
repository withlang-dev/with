//! expect-check-fail: cannot mutate `p` while read-only view `a_view` is live

type Pair {
    a: i32,
    b: i32,
}

fn bad:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    p = Pair { a: 10, b: 20 }
    assert(*a_view == 1)
