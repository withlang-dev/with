//! expect-check-fail: cannot mutate `p` while `a_view` is a live view into it

type Pair {
    a: i32,
    b: i32,
}

fn bad:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    p.a = 10
    assert(*a_view == 1)
