//! expect-debug-alloc: leak count=0
// #2161: an Option and a Result are Clone when their payloads are. The
// clone owns its own payload: both are dropped, each once.
fn a: "A".to_lower()

fn main:
    let some: Option[str] = Some(a())
    let twin = some.clone()
    assert(twin == some and twin == Some("a"))
    let none: Option[str] = None
    assert(none.clone() == None)
    let nested: Option[List[str]] = Some([a(), a()])
    assert((nested.clone() ?? List.new()).len() == 2)
    let ok: Result[str, str] = Ok(a())
    let failed: Result[str, str] = Err("bad".to_lower())
    assert(ok.clone() == Ok("a") and failed.clone() == Err("bad"))
    let numbers: Option[i32] = Some(3)
    assert(numbers.clone() == Some(3))
    // The original still owns its payload.
    assert(some == Some("a") and failed == Err("bad"))
