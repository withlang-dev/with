//! expect-stdout: ok

error ParseError =
    Bad(msg: str)
    Eof

fn describe_error[E: Error](e: &E) -> str:
    e.display()

fn describe_display[D: Display](d: D) -> str:
    d.to_str()

fn describe_debug[D: Debug](d: D) -> str:
    d.debug_str()

fn describe_dyn_error(e: &dyn Error) -> str:
    e.display()

fn dyn_source_is_none(e: &dyn Error) -> bool:
    e.source().is_none()

fn fail_root -> Result[i32, ParseError]:
    Err(.Bad("root"))

fn fail_nested -> Result[i32, ContextError[ParseError]]:
    fail_root().context("middle")?

fn main:
    let plain = ParseError.Bad("plain")
    assert(describe_error(&plain) == "Bad(plain)")

    assert(describe_dyn_error(&plain) == "Bad(plain)")
    assert(dyn_source_is_none(&plain))

    assert(describe_display(ParseError.Bad("display")) == "Bad(display)")
    assert(describe_debug(ParseError.Bad("debug")) == "Bad(debug)")

    let wrapped = fail_root().context("outer").err().unwrap()
    assert(wrapped.display() == "outer")
    let source = wrapped.source()
    assert(source.is_some())
    assert(source.unwrap().display() == "Bad(root)")

    let nested = fail_nested().context("top").err().unwrap()
    let first = nested.source().unwrap()
    assert(first.display() == "middle")
    let second = first.source().unwrap()
    assert(second.display() == "Bad(root)")

    print("ok")
