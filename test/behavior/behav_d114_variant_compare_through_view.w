//! expect-stdout: ok

// §4.2.1 rule 3 (D114): a variant constructor compared with a view is typed
// by the viewed type; `Some(13)` beside `&Option[i32]` is an Option[i32],
// never Option[isize] (which reached MIR as an Option-to-Option cast).
fn get(o: &Option[i32]) -> &Option[i32]: o

fn main:
    let v: Option[i32] = Some(13)
    assert(get(&v) == Some(13))
    assert(Some(13) == get(&v))
    assert(v == Some(13))
    print("ok")
