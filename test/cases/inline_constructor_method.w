// Method calls on inline Option constructors
fn main -> i32:
    // is_some on inline Some
    assert(Some(5).is_some())

    // is_none on None via binding
    let x: ?i32 = None
    assert(x.is_none())

    // Chained: construct then call method
    let v = Some(42)
    assert(v.is_some())

