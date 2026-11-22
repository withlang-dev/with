// Spec test: Section 3 - References and the Second-Class Rule.

fn call_value(f: fn() -> i32) -> i32:
    f()

fn test_reference_as_local:
    let x = 42
    let r = &x
    assert(*r == 42)

fn test_non_escaping_closure_captures_ref:
    let x = 42
    let r = &x
    let y = call_value(() => *r + 1)
    assert(y == 43)
