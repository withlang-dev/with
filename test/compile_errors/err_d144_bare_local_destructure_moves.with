//! expect-check-fail: cannot consume read-only view binding `tx`
// D144 (Eric, 2026-10-22): a bare local is a place; `let (tx, rx) = pair`
// observes it, so moving a part on is refused until `move pair` is spelled.
type Res { n: i32 }
impl Drop for Res:
    move fn drop(): ()
fn consume(r: Res) -> i32: r.n
fn main:
    let pair = (Res { n: 1 }, Res { n: 2 })
    let (tx, rx) = pair
    print(f"{consume(tx)}")
