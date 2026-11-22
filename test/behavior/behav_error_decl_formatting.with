//! expect-stdout: ok
// §10: error enum variants format via Debug (`{:?}`) and Display (`{}`),
// including payload-bearing and payload-less variants.
enum ParseError:
    Bad(i32)
    Eof
enum AppError:
    Parse(ParseError)
fn main:
    let w = AppError.Parse(ParseError.Bad(9))
    assert(f"{w:?}" == "Parse(Bad(9))")
    assert(f"{w}" == "Parse(Bad(9))")
    let e = AppError.Parse(ParseError.Eof)
    assert(f"{e:?}" == "Parse(Eof)")
    print("ok")
