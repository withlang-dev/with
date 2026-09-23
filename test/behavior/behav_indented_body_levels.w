//! expect-stdout: 3 3 1 2 zero many
//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 1 2

// #1391 (§29.13 Form 2): an indented body sits deeper than the line holding
// its construct. Continuation lines, an `if` inside a `let`, an arm body
// after `=>`, a closure body, a body inside an inline body, and a colon body
// inside braces (where the statement's own line is the level) all qualify.
type P { n: i32 }

impl P:
    fn get() -> i32:
        self.n

fn wide(a: i32,
        b: i32) -> i32:
    a + b

fn pick(c: bool) -> i32:
    let v = if c:
        1
    else:
        2
    v

fn arm(n: i32) -> str:
    match n:
        0 =>
            "zero"
        _ => "many"

fn braced(c: bool) -> i32 {
  if c:
     return 1
  2
}

fn main:
    let p = P { n: 3 }
    print(f"{p.get()} {wide(1, 2)} {pick(true)} {pick(false)} {arm(0)} {arm(5)}")
    let add = (x: i32) =>
        x + 1
    print(f"{add(1)}")
    var total = 0
    for i in 0..3: if i > 0:
        total += i
    print(f"{total}")
    print(f"{braced(true)} {braced(false)}")
