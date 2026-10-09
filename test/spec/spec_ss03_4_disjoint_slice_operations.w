// Spec test: Section 3.6 — Disjoint field/index access.
// Array/slice index disjointness is not inferred; use get_disjoint for
// explicit, checked simultaneous access to distinct collection elements.

fn filled_list() -> List[i32]:
    var xs = List.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs

fn test_get_disjoint_mutates_distinct_elements:
    var xs = filled_list()
    with xs.get_disjoint(0, 2) as mut (left, right):
        left.set(10)
        right.set(30)
    assert(xs[0] == 10)
    assert(xs[1] == 2)
    assert(xs[2] == 30)

fn test_get_disjoint_read_only_slots:
    var xs = filled_list()
    with xs.get_disjoint(0, 1) as (left, right):
        assert(left.get() == 1)
        assert(right.get() == 2)
