//! expect-stdout: found 12
//! expect-stdout: pairs 00 01 10 11 20 21
//! expect-stdout: until 00 01 02 10
//! expect-stdout: point 3 4
//! expect-stdout: none

// D69 (§13.4): the consumer's control flow crosses nested generator loops —
// a `return` from the inner loop leaves both generators and the function,
// a labeled `continue` / `break` reaches the outer loop, and a returned
// aggregate travels to the caller.
gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

type Point {
    x: i32,
    y: i32,
}

fn find(target: i32) -> str:
    for a in upto(5):
        for b in upto(5):
            if a * 10 + b == target:
                return f"found {a}{b}"
    "none"

fn first_point(limit: i32) -> Option[Point]:
    for a in upto(10):
        for b in upto(10):
            if a + b == limit and a == 3:
                return Some(Point { x: a, y: b })
    None

fn main:
    print(find(12))
    var pairs = "pairs"
    'outer for a in upto(3):
        for b in upto(5):
            if b == 2: continue 'outer
            pairs = pairs ++ f" {a}{b}"
    print(pairs)
    var until = "until"
    'rows for a in upto(3):
        for b in upto(3):
            if a == 1 and b == 1: break 'rows
            until = until ++ f" {a}{b}"
    print(until)
    match first_point(7):
        Some(p) => print(f"point {p.x} {p.y}")
        None => print("no point")
    print(find(99))
