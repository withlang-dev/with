//! expect-stdout: ok
// §10.3.1.5: `opt?.method()` where the method returns Option FLATTENS (no
// Option[Option[T]]); a None receiver short-circuits.
type Parser { n: i32 }
impl Parser:
    fn digit(self: &Self, i: i32) -> Option[i32]:
        if i < self.n: Some(i) else: None

fn unwrap_or(o: Option[i32], d: i32) -> i32:
    match o:
        Some(v) => v
        None => d

fn main:
    let p: Option[Parser] = Some(Parser { n: 3 })
    let none_p: Option[Parser] = None
    let r1: Option[i32] = p?.digit(2)
    let r2: Option[i32] = p?.digit(5)
    let r3: Option[i32] = none_p?.digit(2)
    assert(unwrap_or(r1, -1) == 2)
    assert(unwrap_or(r2, -1) == -1)
    assert(unwrap_or(r3, -1) == -1)
    print("ok")
