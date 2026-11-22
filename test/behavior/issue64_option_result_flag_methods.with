fn main:
    let opt: Option[i32] = Some(1)
    let none_opt: Option[i32] = None
    assert(opt.is_some())
    assert(not opt.is_none())
    assert(none_opt.is_none())

    let ok: Result[i32, str] = Ok(2)
    let err: Result[i32, str] = Err("nope")
    assert(ok.is_ok())
    assert(not err.is_ok())
