//! expect-stdout: 3 4
//! expect-stdout: drop 3
//! expect-stdout: 3
//! expect-stdout: drop 4

// D144 (Eric, 2026-10-22): a bare local is a place too. `let (a, b) =
// pair` observes `pair` (the bindings are views of its parts, read
// through them), and taking the pair apart is spelled `move pair`.
type Res { n: i32 }
impl Drop for Res:
    move fn drop(): print(f"drop {self.n}")

fn consume(r: Res) -> i32: r.n

fn main:
    let pair = (Res { n: 3 }, Res { n: 4 })
    let (a, b) = pair
    print(f"{a.n} {b.n}")
    let (x, y) = move pair
    print(f"{consume(x)}")
