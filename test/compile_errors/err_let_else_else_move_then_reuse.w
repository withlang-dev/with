//! expect-check-fail: use of moved value

// #1383: the else branch's move stays on its own path, but the matched path
// is still checked — a value it consumes cannot be read afterwards. A List,
// not a str: a str argument is copied (D111).
fn list_or_err(k: i32) -> Result[List[str], str]:
    if k == 0: return Err("none")
    var v: List[str] = List.new()
    v.push("a")
    v

fn consume(v: List[i32]) -> i32: v.len() as i32

fn h(k: i32) -> i32:
    let keep: List[i32] = [1, 2, 3, 4]
    let Ok(v) = list_or_err(k) else: return consume(keep) - 100
    let n = consume(keep)
    n + keep.len() as i32 + v.len() as i32

fn main:
    print(h(1))
