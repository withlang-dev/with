//! expect-stdout: ok

// A match-arm block whose tail is `move taken.field` is the same lazy
// OK_MOVE hazard as a fn-body tail: the arm block's scope-exit drop of
// `taken` must come AFTER the moved field is materialized. Before the
// fix this returned an empty str.

type M { text: str, n: i32 }

fn mk() -> Option[M]: Some(M { text: "hi" ++ "", n: 1 })

fn take_text() -> str:
    match mk():
        Some(found) => { var taken = found; move taken.text }
        None => ""

fn main:
    assert(take_text() == "hi")
    print("ok")
