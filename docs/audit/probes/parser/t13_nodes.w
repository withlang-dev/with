// T13: AST node-coverage: one file exercising the parser's NK_* emissions.
fn add(x: i32, y: i32) -> i32:
    x + y

type Pair:
    a: i32
    b: i32

enum Color:
    Red
    Green
    Blue

fn main:
    let t = (1, "two")
    let arr = [1, 2, 3]
    let m = ["k": 1]
    let p = Pair { a: 1, b: 2 }
    let c: Color = .Red
    let cl = (x) => x + 1
    assert(cl(41) == 42)
    let casted = 1 as i64
    assert(casted == 1i64)
    let r = 1..=3
    let piped = 5 |> add(10)
    assert(piped == 15)
    let opt: ?i32 = .Some(7)
    assert((opt ?? 0) == 7)
    let t2 = if true: 1 else: 2
    assert(t2 == 1)
    let mv = match c:
        .Red => 1
        _ => 0
    assert(mv == 1)
    var total = 0
    for x in arr:
        total = total + x
    assert(total == 6)
    var i = 0
    while i < 3:
        i = i + 1
    assert(i == 3)
    let s = f"total={total}"
    assert(s == "total=6")
    let n: ?i32 = .None
    assert((n ?? 42) == 42)
