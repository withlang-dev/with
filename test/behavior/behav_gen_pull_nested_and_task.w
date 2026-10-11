//! expect-stdout: 101 202 303
//! expect-stdout: task sum 66
//! expect-stdout: pulled twice: 5 6 | 5 6 7

// D69 (§13.4 Pulling): a pulled generator may itself pull another (one
// coroutine resumed from inside another), a pulled generator can be stepped
// from inside a task — its fiber is resumed by next(), not scheduled — and
// two pulls of the same generator function are independent.
gen fn units(n: i32) -> i32:
    for i in 1..n + 1:
        yield i

gen fn scaled(n: i32) -> i32:
    var inner = units(n).pull()
    while true:
        match inner.next():
            Some(u) => yield u * 101
            None => break

async fn sum_pulled(n: i32) -> i32:
    var p = units(n).pull()
    var total: i32 = 0
    while true:
        match p.next():
            Some(u) => total += u * 11
            None => break
    total

fn main:
    var s = scaled(3).pull()
    let a = s.next().unwrap()
    let b = s.next().unwrap()
    let c = s.next().unwrap()
    print(f"{a} {b} {c}")
    let t = sum_pulled(3)
    print(f"task sum {t.await}")
    var x = units(7).pull()
    var y = units(7).pull()
    for _ in 0..4:
        let _ = x.next()
    for _ in 0..4:
        let _ = y.next()
    let x5 = x.next().unwrap()
    let y5 = y.next().unwrap()
    let x6 = x.next().unwrap()
    let y6 = y.next().unwrap()
    let y7 = y.next().unwrap()
    print(f"pulled twice: {x5} {x6} | {y5} {y6} {y7}")
