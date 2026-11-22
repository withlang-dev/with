//! expect-error: retired
// §13.6a (D185): `for x in opt: yield e` was the one-clause yield form; `[e for x in opt]` is the spelling.
fn a() -> Option[i32]: Some(1)
fn main:
    let r = for x in a(): yield x + 1
    print(f"{r:?}")
