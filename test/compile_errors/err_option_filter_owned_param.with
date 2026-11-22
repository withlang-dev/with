//! expect-check-fail: Option.filter

// #1379 (§10.5): the filter predicate is `fn(&T) -> bool` — it observes the
// payload, which then moves into the kept `Some`. A parameter spelled as an
// owned `T` would claim the payload the result keeps.
type P { name: str }

fn main:
    let o: Option[P] = Some(P { name: "p" ++ "q" })
    let m = o.filter((q: P) => q.name.len() > 0)
    print(m.is_some())
