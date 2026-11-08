//! expect-stdout: none
//! expect-stdout: quiet
//! expect-stdout: 7
// #3088: the bare variant table named whichever enum registered last, so
// with `mode_with_none` imported an undemanded `None` was `Mode.None` and
// the Option binding below was refused ("type mismatch in binding"). A
// bare name resolves by scope: this module's own enums, then the prelude's
// Option/Result, then the one visible enum that declares it.
use mode_with_none

fn main:
    let x = None
    let y: Option[i32] = x
    print(if y.is_none(): "none" else: "some")
    print(mode_name(Mode.None))
    let z: Option[i32] = Some(7)
    print(f"{z.unwrap()}")
