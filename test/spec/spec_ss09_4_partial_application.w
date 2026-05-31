// Spec test: Section 9.4 — Partial Application
// Executable subset (vec!/pipeline/collect and the no-implicit-currying error case omitted).

fn add(a: i32, b: i32) -> i32: a + b

fn test_partial_first_arg:
    let add5 = add(5, _)
    assert(add5(3) == 8)

fn test_partial_second_arg:
    let inc = add(_, 1)
    assert(inc(10) == 11)
