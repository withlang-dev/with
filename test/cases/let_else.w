fn get_some() -> ?i32 =
    Some(42)

fn get_none() -> ?i32 =
    None

fn main() -> i32 =
    // Test 1: let Some(x) = expr else return
    let Some(val) = get_some() else return 1
    assert(val == 42)

    // Test 2: let Some(x) = None else provides default flow
    let Some(val2) = get_none() else return 0

    // Should not reach here
    val2
