//! expect-stdout: ok

error LowError =
    | Bad(code: i32)

error MidError from LowError
error TopError from MidError
error RootError from TopError

error OtherError =
    | Other

error MixedError from MidError, OtherError

fn low_fail -> Result[i32, LowError]:
    Err(.Bad(7))

fn top_fail -> Result[i32, TopError]:
    low_fail()?

fn root_fail -> Result[i32, RootError]:
    low_fail()?

fn mixed_fail -> Result[i32, MixedError]:
    low_fail()?

fn main:
    let top_code = match top_fail():
        Err(TopError.Mid(MidError.Low(LowError.Bad(code)))) => code
        _ => 0
    let root_code = match root_fail():
        Err(RootError.Top(TopError.Mid(MidError.Low(LowError.Bad(code))))) => code
        _ => 0
    let mixed_code = match mixed_fail():
        Err(MixedError.Mid(MidError.Low(LowError.Bad(code)))) => code
        _ => 0
    assert(top_code == 7)
    assert(root_code == 7)
    assert(mixed_code == 7)
    print("ok")
