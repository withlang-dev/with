//! expect-stdout: 1 3
//! expect-stdout: 20 3
//! expect-stdout: 5 4

// D144: a binding from a join of plain-bits places — `if c: self.a else:
// self.b`, a `match` of fields or elements — is a binding from a place, so
// it takes the value as `let x = self.a` does, and a write of the receiver
// after it is fine.
type Lanes { a: i32, b: i32, xs: List[i32], n: i32 }

impl Lanes:
    mut fn bump(): self.n += 1
    mut fn pick(c: bool) -> i32:
        let x = if c: self.a else: self.b
        self.bump()
        x
    mut fn pick_element(i: i32) -> i32:
        let x = if i == 0: self.xs[0] else if i == 1: self.xs[1] else: self.a
        self.xs.push(x)
        self.bump()
        x
    mut fn pick_match(k: i32) -> i32:
        let x = match k:
            0 => self.a
            1 => self.b
            _ => self.xs[2]
        self.bump()
        x

fn main:
    var l = Lanes { a: 1, b: 2, xs: [10, 20, 5], n: 0 }
    print(f"{l.pick(true)} {l.n + 2}")
    print(f"{l.pick_element(1)} {l.xs.len() - 1}")
    print(f"{l.pick_match(2)} {l.n + 1}")
