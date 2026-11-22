//! expect-stdout: ok=[val=11 rel=1] err=[boom rel=1]
// §23.3.1.8 / §7.7.1.6: `?` inside a `with` block propagates the error to the
// enclosing function; the guard is released as the block unwinds.
var REL = 0
type Guard {}
impl Scoped[i32] for Guard:
    fn with_enter(self: &Self) -> i32: 0
    fn with_exit(self: &Self) -> Unit: REL = REL + 1

fn maybe(fail: bool) -> Result[i32, str]:
    if fail: return Err("boom")
    Ok(10)

fn compute(fail: bool) -> Result[i32, str]:
    var out = 0
    let g = Guard {}
    with g as d:
        let x = maybe(fail)?
        out = x + 1
    Ok(out)

fn main:
    REL = 0
    let a = compute(false)
    let ra = REL
    REL = 0
    let b = compute(true)
    let rb = REL
    let ok_s = match a:
        Ok(v) => f"val={v} rel={ra}"
        Err(e) => f"{e} rel={ra}"
    let err_s = match b:
        Ok(v) => f"val={v} rel={rb}"
        Err(e) => f"{e} rel={rb}"
    print(f"ok=[{ok_s}] err=[{err_s}]")
