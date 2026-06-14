//! expect-stdout: ok

error LetElseError =
    | Bad

fn from_option(opt: Option[i32]) -> i32:
    let Some(v) = opt else return -1
    v

fn from_option_shorthand(opt: Option[i32]) -> i32:
    let .Some(v) = opt else return -1
    v

fn from_result(res: Result[i32, LetElseError]) -> Result[i32, LetElseError]:
    let Ok(v) = res else return Err(.Bad)
    v + 1

fn main:
    assert(from_option(Some(10)) == 10)
    assert(from_option(None) == -1)
    assert(from_option_shorthand(Some(20)) == 20)
    assert(from_option_shorthand(None) == -1)
    assert(from_result(Ok(4)).unwrap() == 5)
    match from_result(Err(.Bad)):
        Err(LetElseError.Bad) => {}
        _ => assert(false)
    print("ok")
