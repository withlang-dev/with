//! expect-stdout: ok

fn maybe_number(ok: bool) -> ?i32:
    if ok:
        return .Some(7)
    .None

fn maybe_label(ok: bool) -> ?str:
    let _ = maybe_number(ok)?
    .Some("ok")

fn main:
    assert(maybe_label(true).unwrap() == "ok")
    assert(maybe_label(false).is_none())
    print("ok")
