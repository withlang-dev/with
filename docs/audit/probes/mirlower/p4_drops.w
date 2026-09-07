fn consume(s: str) -> i32:
    s.len()

fn main:
    let a = "hello"
    let b = a
    print(f"b={b} n={consume("x" ++ "y")}")
    var s = "one"
    s = "two"
    print(s)
    let v = [1, 2, 3]
    var total = 0
    for x in v:
        total = total + x
    print(f"total={total}")
