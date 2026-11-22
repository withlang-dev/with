//! expect-stdout: alpha
//! expect-stdout: beta
// #2187: a view returned through a match arm's pattern binding views what
// the matched payload views, so it is good for as long as that is
// (explain:origin:at_match: "only through what it views").
type Thing { name: str }
enum Src ephemeral:
    One(&Thing)
    Two(&Thing)

fn at_match(s: &Src) -> &str:
    match s:
        .One(v) => &v.name
        .Two(v) => &v.name

let a = Thing { name: "alpha".to_owned() }
let b = Thing { name: "beta".to_owned() }
print(at_match(&Src.One(&a)))
print(at_match(&Src.Two(&b)))
