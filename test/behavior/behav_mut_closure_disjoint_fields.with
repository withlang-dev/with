// Test: §9.2 disjoint field captures in closures

type Point { x: i32, y: i32 }

fn call_mutator(f: fn() -> Unit):
    f()

fn apply_two(a: fn() -> Unit, b: fn() -> Unit):
    a()
    b()

fn use_ref_and_closure(r: &i32, f: fn() -> Unit):
    let _ = *r
    f()

// PASS: two closures mutating disjoint fields
fn test_disjoint_field_mutation:
    var p = Point { x: 1, y: 2 }
    apply_two(() => p.x = 10, () => p.y = 20)
    assert(p.x == 10)
    assert(p.y == 20)

// PASS: read + write of disjoint fields in closures
fn test_read_write_disjoint_fields:
    var p = Point { x: 5, y: 10 }
    apply_two(() => p.x = p.x + 1, () => p.y = p.y + 1)
    assert(p.x == 6)
    assert(p.y == 11)

// PASS: reference to disjoint field as sibling arg
fn test_ref_sibling_disjoint:
    var p = Point { x: 1, y: 2 }
    use_ref_and_closure(&p.y, () => p.x = 10)
    assert(p.x == 10)
