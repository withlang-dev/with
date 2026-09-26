//! expect-check-fail: undefined variable
// #1476: the else branch runs only when the pattern did not match, so a name
// the pattern binds does not exist there (§9.7).
fn vec_or_err(k: i32) -> Result[Vec[str], str]:
    if k == 0: return Err("none".clone())
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v
fn h(k: i32) -> i32:
    let Ok(v) = vec_or_err(k) else: return v.len() as i32
    v.len() as i32
fn main:
    print(f"{h(0)}")
