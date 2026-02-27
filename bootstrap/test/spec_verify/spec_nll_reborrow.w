// POSITIVE: NLL — borrow ends at last use, allowing reborrow (§3.5)
fn main -> i32:
    let mut x: i32 = 10
    let r = &x
    let v = *r
    // r is no longer used after this point — borrow ends (NLL)
    let rmx = &mut x
    *rmx = 42
    assert(*rmx == 42)
    println("nll reborrow ok")
