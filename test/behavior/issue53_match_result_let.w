//! expect-stdout: ok

error E =
    Bad

fn maybe(ok: bool) -> Result[i32, E]:
    if not ok:
        return Err(.Bad)
    Ok(7)

fn maybe_opt(ok: bool) -> Option[i32]:
    if ok:
        return Some(7)
    None

fn two_returns(ok: bool) -> Result[i32, str]:
    if ok:
        return Ok(7)
    return Err("bad")

fn test_match_result_let:
    let got_err = match maybe(false)
        Err(.Bad) => true
        _ => false
    assert(got_err)

fn test_match_result_ok:
    let got_ok = match maybe(true)
        Ok(n) => n == 7
        _ => false
    assert(got_ok)

fn test_two_returns:
    let r1 = two_returns(true)
    let r2 = two_returns(false)
    let ok_val = match r1
        Ok(n) => n
        _ => 0
    assert(ok_val == 7)
    let is_err = match r2
        Err(_) => true
        _ => false
    assert(is_err)

fn test_option_return:
    let r = maybe_opt(true)
    let val = match r
        Some(n) => n
        None => 0
    assert(val == 7)

fn main:
    test_match_result_let()
    test_match_result_ok()
    test_two_returns()
    test_option_return()
    print("ok")
