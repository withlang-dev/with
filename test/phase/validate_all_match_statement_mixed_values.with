//! args: --validate-all
//! expect-check-stdout: validate-all: ok

fn main:
    var out = ""
    let found: Option[str] = Some("x")
    match found:
        Some(value) => out = out ++ value
        None => {}
    assert(out == "x")
