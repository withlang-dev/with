//! expect-stdout: 42 6 3 10 12 9

// D126 (§4.2.1): a local its literal typed takes the type its demanding
// uses agree on. `var total = 0` returned as i32, `var sum = 0` as an Ok
// payload, `var x = 40` handed to an i32 parameter, a local reaching an i32
// parameter through arithmetic, and a list literal handed to a `[]i32`
// parameter are typed by those uses; the programmer writes nothing. A local
// nothing narrows stays isize.
fn column() -> i32: 21

fn total_of() -> i32:
    var total = 0
    let add = n => total = total + n
    add(column())
    add(column())
    total

fn summed(ok: bool) -> Result[i32, str]:
    if not ok: return Err("no")
    var sum = 0
    for v in [1, 2, 3]: sum += v as i32
    sum

fn sample(x: i32, y: i32) -> i32: x + y
fn pay(n: i32) -> i32: n
fn tot(values: []i32) -> i32:
    var t: i32 = 0
    for v in values: t += v
    t

fn main:
    var y = 1
    var hits = 0
    while y < 3:
        var x = 1
        while x < 3:
            if sample(x, y) > 2: hits = hits + 1
            x = x + 1
        y = y + 1
    var untouched = 10
    var bonus = 7
    let paid = pay(bonus + 5)
    let values = [4, -2, 7]
    print(f"{total_of()} {summed(true).unwrap()} {hits} {untouched} {paid} {tot(values)}")
