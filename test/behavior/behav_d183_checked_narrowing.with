//! expect-stdout: 70000 7 3 5 9 -4 12 1 2
// §4.2.6 (D183, #2522): an integer where a narrower integer or the other
// signedness is demanded converts with a range check; in range, every
// demand position takes it with no `as`.
type Box { n: i32 }
enum Shape:
    Width(i32)
fn take(n: i32) -> i32: n
fn ret(x: i64) -> i32: x
fn main:
    let big: i64 = 70000
    let small: i32 = big
    let xs = [1, 2, 3]
    let count: i32 = xs.len()
    var acc: i32 = 0
    acc = big - 69997 + count
    let b = Box { n: ret(5) }
    let w: i64 = 9
    let s = Shape.Width(w)
    let m = match s:
        Shape.Width(v) => v
    let neg: i64 = -4
    let n: i32 = neg
    let u: u32 = 12 as i64
    let t: (i32, i32) = (1 as i64, 2 as i64)
    print(f"{small} {take(7 as i64)} {count} {b.n} {m} {n} {u} {t.0} {t.1}")
