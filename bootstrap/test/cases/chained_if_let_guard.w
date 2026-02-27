// Chained if-let with boolean guard
fn get_val -> ?i32: Some(42)
fn get_name -> ?str: Some("world")
fn get_none -> ?i32: None

fn main -> i32:
    // Three-clause: let, guard, let (with multiline body)
    let r1 = if let Some(x) = get_val(), x > 0, let Some(name) = get_name():
        println(x)
        println(name)
        x
    else
        0
    assert(r1 == 42)

    // Guard fails
    let r2 = if let Some(x) = get_val(), x > 100, let Some(name) = get_name():
        x
    else
        99
    assert(r2 == 99)

    // First let fails
    let r3 = if let Some(x) = get_none(), x > 0:
        x
    else
        77
    assert(r3 == 77)

