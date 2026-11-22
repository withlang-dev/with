//! expect-error: ambiguous error conversion

error LowError =
    | Bad

error MidAError from LowError
error MidBError from LowError
error TopError from MidAError, MidBError

fn low_fail -> Result[i32, LowError]:
    Err(.Bad)

fn top_fail -> Result[i32, TopError]:
    low_fail()?

fn main:
    let _ = top_fail()
