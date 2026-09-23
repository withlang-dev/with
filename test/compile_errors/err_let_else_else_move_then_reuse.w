//! expect-check-fail: use of moved value

// #1383: the else branch's move stays on its own path, but the matched path
// is still checked — a value it consumes cannot be read afterwards.
fn vec_or_err(k: i32) -> Result[Vec[str], str]:
    if k == 0: return Err("none".clone())
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v

fn consume(s: str) -> i32: s.len() as i32

fn h(k: i32) -> i32:
    let keep = "keep".clone()
    let Ok(v) = vec_or_err(k) else: return consume(keep) - 100
    let n = consume(keep)
    n + keep.len() as i32 + v.len() as i32

fn main:
    print(h(1))
