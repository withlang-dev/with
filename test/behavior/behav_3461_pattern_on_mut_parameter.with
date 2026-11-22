//! expect-stdout: a!
//! expect-stdout: 4
//! expect-stdout: 2

// A `mut` parameter is the caller's place (§3.8a): a pattern on it
// observes it. It was judged an owned subject, so a variant payload bound
// from it was moved out and the mutation through the binding was lost
// (this printed `a`), and a list pattern on one was refused as a move.
type Tag { name: str }
impl Tag:
    mut fn grow(): self.name = self.name ++ "!"

enum E:
    A(t: Tag)
    Z

fn bump(mut e: E):
    match e:
        .A(t) => t.grow()
        .Z => ()

fn peek(mut xs: List[Tag]) -> i32:
    match xs:
        [h, ..rest] => h.name.len() as i32 + rest.len() as i32
        _ => 0

fn main:
    var e: E = .A(Tag { name: "a" })
    bump(e)
    match e:
        .A(t) => print(t.name)
        .Z => print("z")
    var xs = [Tag { name: "one" }, Tag { name: "two" }]
    print(peek(xs))
    print(xs.len())
