//! expect-check-fail: cannot mutate `p` while `whole` is a live view into it

type Pair {
    a: i32,
    b: i32,
}

fn bad:
    var p = Pair { a: 1, b: 2 }
    let whole = &p
    p.a = 10
    assert((*whole).a == 1)
