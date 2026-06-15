// Spec test: Section 8.2 — reference counting is explicit Rc/Arc.

fn test_rc_reference_counting_is_explicit:
    let a = Rc.new(11)
    assert(a.strong_count() == 1)
    let b = a.clone()
    assert(a.strong_count() == 2)
    assert(b.strong_count() == 2)
    assert(*a.as_ref() == 11)

fn test_arc_reference_counting_is_explicit:
    let a = Arc.new(13)
    assert(a.strong_count() == 1)
    let b = a.clone()
    assert(a.strong_count() == 2)
    assert(b.strong_count() == 2)
    assert(*a.as_ref() == 13)
