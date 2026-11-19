//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 1
//! expect-stdout: 1 7 0
//! expect-stdout: 1 2 3 0

// #823 (§9.7): a subject that is observed, not consumed. The shared name
// is the payload in place (a mutating call through it writes the subject);
// through a borrowed subject it is a view; a guard reads it; `..` composes;
// three alternatives.
type Tag { name: str }
impl Tag:
    fn status() -> i32: self.name.len() as i32
    mut fn grow(): self.name = self.name ++ "!"

enum E:
    C(t: Tag, n: i32)
    D(n: i32, t: Tag)
    Z

enum N:
    A(n: i32, s: str)
    B(s: str, n: i32)
    Only(n: i32)
    None0

fn status_of(e: &E) -> i32:
    match e:
        .C(t, ..) | .D(_, t) => t.status()
        _ => 0

fn guard_copy(e: &N) -> i32:
    match e:
        .A(n, _) | .B(_, n) | .Only(n) if *n > 10 => 1
        .A(n, _) | .B(_, n) | .Only(n) => *n
        .None0 => 0

fn three(e: N) -> i32:
    match e:
        .A(n, ..) | .B(_, n) | .Only(n) => n
        .None0 => 0

fn main:
    var e: E = .D(1, Tag { name: "dd" })
    print(status_of(e))
    match e:
        .C(t, _) | .D(_, t) => t.grow()
        _ => ()
    print(status_of(e))
    let f: E = .C(Tag { name: "c" }, 2)
    print(status_of(f))
    let big: N = .Only(50)
    let small: N = .B("x", 7)
    print(f"{guard_copy(big)} {guard_copy(small)} {guard_copy(.None0)}")
    print(f"{three(.A(1, "a"))} {three(.B("b", 2))} {three(.Only(3))} {three(.None0)}")
