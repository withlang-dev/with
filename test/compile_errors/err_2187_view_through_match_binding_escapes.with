//! expect-error: returned view may outlive its origin 's'
// #2187: a view reached through a match arm's pattern binding still escapes
// the parameter the subject came from; returning it past its origin is
// refused.
type Thing { name: str }
enum Src ephemeral:
    One(&Thing)
    Two(&Thing)

fn at_match(s: &Src) -> &str:
    match s:
        .One(v) => &v.name
        .Two(v) => &v.name

fn outer() -> &str:
    let t = Thing { name: "alpha".to_owned() }
    let s: Src = .One(&t)
    at_match(&s)

fn main:
    print(outer())
