//! expect-stdout: 1 8 9

// #615: what stays legal. A closure that only reads the place another
// argument borrows; a closure that writes one field while a view of a
// sibling field is live; a closure that writes a place nothing else holds.
type P { a: List[i64], b: i32 }

fn both(a: &List[i64], body: fn() -> i32) -> i32: body()
fn run(body: fn() -> i32) -> i32: body()

fn main:
    var xs: List[i64] = [7]
    let k = both(xs, () => xs.len() as i32)
    var p = P { a: [7], b: 0 }
    let v = &p.a[0]
    let r = run(() => {
        p.b += 1
        p.b
    })
    let viewed = *v + r as i64
    var n = 0
    let q = run(() => {
        n += 9
        n
    })
    print(f"{k} {viewed} {q}")
