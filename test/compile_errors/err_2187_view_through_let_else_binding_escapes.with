//! expect-error: returned view may outlive its origin 's'
// #2187: the let-else form of the same escape.
type Thing { name: str }
enum Src ephemeral:
    One(&Thing)
    Two(&Thing)

fn first(s: &Src) -> &str:
    let .One(v) = s else: return "none"
    &v.name

fn outer() -> &str:
    let t = Thing { name: "alpha".to_owned() }
    let s: Src = .One(&t)
    first(&s)

fn main:
    print(outer())
