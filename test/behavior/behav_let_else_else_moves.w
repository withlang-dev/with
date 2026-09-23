//! expect-stdout: -96 5
//! expect-stdout: -99 4

// #1383 (§2.2, §9.7): a let-else's else branch diverges, so a value it moves
// is moved on that path only; the matched path still owns it and reads it
// whole. `if … : return consume(keep)` was always accepted; the let-else
// spelling was rejected as a use after move.
fn vec_or_err(k: i32) -> Result[Vec[str], str]:
    if k == 0: return Err("none".clone())
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v

fn consume(s: str) -> i32: s.len() as i32

type Holder { f: str, g: str }

fn h(k: i32) -> i32:
    let keep = "keep".clone()
    let Ok(v) = vec_or_err(k) else: return consume(keep) - 100
    keep.len() as i32 + v.len() as i32

fn field(k: i32) -> i32:
    var b = Holder { f: "f".clone(), g: "gg".clone() }
    let Ok(v) = vec_or_err(k) else: return consume(move b.f) - 100
    b.f.len() as i32 + b.g.len() as i32 + v.len() as i32

fn main:
    print(f"{h(0)} {h(1)}")
    print(f"{field(0)} {field(1)}")
