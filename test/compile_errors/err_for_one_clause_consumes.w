//! expect-error: use of moved value

// §13.6a: a one-clause comprehension consumes its clause like the match it
// is equivalent to; the Option is gone afterwards.
fn main:
    let o = Some("a" ++ "b")
    for x in o:
        print(x)
    print(f"{o:?}")
