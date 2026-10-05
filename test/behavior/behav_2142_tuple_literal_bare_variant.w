//! expect-stdout: ok
// #2142: of two tuple literals compared, the one a bare variant left open
// takes the other's type, on either side.
fn main:
    assert((Some("a".to_lower()), 1) != (None, 1))
    assert((None, 1) != (Some("a".to_lower()), 1))
    let absent: Option[str] = None
    assert((absent, 2) == (None, 2))
    print("ok")
