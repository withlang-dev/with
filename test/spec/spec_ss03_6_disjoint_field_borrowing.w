// Spec test: Section 3.6 — Disjoint Field Access.

type Pair {
    a: i32,
    b: i32,
}

type Deep {
    inner: Pair,
    other: i32,
}

fn test_distinct_fields_mutate_while_view_live:
    var p = Pair { a: 1, b: 2 }
    let a_view = &p.a
    p.b = 20
    assert(*a_view == 1)
    assert(p.b == 20)

fn test_nested_disjoint_fields_mutate_while_view_live:
    var d = Deep { inner: Pair { a: 1, b: 2 }, other: 3 }
    let a_view = &d.inner.a
    d.inner.b = 20
    d.other = 30
    assert(*a_view == 1)
    assert(d.inner.b == 20)
    assert(d.other == 30)
