// Test: with tuple destructuring (§10.2)

fn make_pair() -> (i32, i32):
    (1, 2)

fn make_triple() -> (i32, i32, i32):
    (1, 2, 3)

// Immutable read
fn test_immutable_read:
    let p = make_pair()
    with p as (a, b):
        assert(a == 1)
        assert(b == 2)
        assert(a + b == 3)

// Mutable Form 2: mutations propagate back
fn test_mutable_form2:
    let p = make_pair()
    let t = with p as mut (a, b):
        a = a + 10
        b = b + 20
    assert(t.0 == 11)
    assert(t.1 == 22)

// Wildcard binding
fn test_wildcard:
    let tr = make_triple()
    with tr as (a, _, c):
        assert(a == 1)
        assert(c == 3)

// Mutable with non-Unit body returns body value
fn test_mutable_non_unit:
    let p = make_pair()
    let result = with p as mut (a, b):
        a = a + 10
        a + b
    assert(result == 13)
