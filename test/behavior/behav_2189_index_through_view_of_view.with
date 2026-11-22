//! expect-stdout: 2
//! expect-stdout: b
// #2189: matching a view payload through a view of its enum binds
// `&&List[str]`; indexing dereferences through both views.
enum Src ephemeral:
    One(&List[str])

let xs: List[str] = ["a".to_owned(), "b".to_owned()]
let s: Src = .One(&xs)
match &s:
    .One(v) =>
        print(v.len())
        print(v[1])
