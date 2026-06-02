// Spec test: Section 10.6 — Error Context (formerly 25.43)

fn fallible(value: i32) -> Result[i32, str]:
    if value < 0:
        Err("negative")
    else:
        Ok(value)

fn add_context(value: i32) -> Result[i32, ContextError[str]]:
    fallible(value).context("outer")?

fn test_context_wraps_error:
    let result = add_context(-1)
    match result:
        Ok(_) => assert(false)
        Err(e) =>
            assert(e.message == "outer")
            assert(e.source == "negative")

fn test_context_preserves_ok:
    assert(add_context(7).unwrap() == 7)

fn test_with_context_wraps_error:
    let result = fallible(-2).with_context(() => "lazy")
    match result:
        Ok(_) => assert(false)
        Err(e) =>
            assert(e.message == "lazy")
            assert(e.source == "negative")

fn test_with_context_is_lazy_on_ok:
    let result = fallible(3).with_context(() => unreachable("with_context closure ran on Ok"))
    assert(result.unwrap() == 3)
