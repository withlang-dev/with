//! expect-stdout: ok

fn ok_i32(value: i32) -> Result[i32, str]:
    Ok(value)

fn err_i32(message: str) -> Result[i32, str]:
    Err(message)

fn double_checked(value: i32) -> Result[i32, str]:
    Ok(value * 2)

fn fail_checked(value: i32) -> Result[i32, str]:
    Err("fail")

fn recover_to_code(message: str) -> Result[i32, i32]:
    Err(message.len() as i32)

fn fallback_from_error(message: str) -> i32:
    message.len() as i32

fn main:
    assert(ok_i32(5).and_then(v => double_checked(v)).unwrap() == 10)
    match err_i32("bad").and_then(v => fail_checked(v)):
        Err(e) => assert(e == "bad")
        Ok(_) => assert(false)

    match err_i32("oops").or_else(e => recover_to_code(e)):
        Err(code) => assert(code == 4)
        Ok(_) => assert(false)
    assert(ok_i32(6).or_else(e => recover_to_code(e)).unwrap() == 6)

    assert(ok_i32(7).unwrap_or_else(e => unreachable("Result.unwrap_or_else ran on Ok")) == 7)
    assert(err_i32("four").unwrap_or_else(e => fallback_from_error(e)) == 4)

    assert(ok_i32(8).ok().unwrap() == 8)
    assert(ok_i32(8).err().is_none())
    assert(err_i32("missing").ok().is_none())
    assert(err_i32("missing").err().unwrap() == "missing")

    var ok_seen: Vec[i32] = Vec.new()
    let inspected_ok = ok_i32(9).inspect(_value => ok_seen.push(1))
    assert(inspected_ok.unwrap() == 9)
    assert(ok_seen.len32() == 1)
    match err_i32("skip").inspect(_value => unreachable("Result.inspect ran on Err")):
        Err(e) => assert(e == "skip")
        Ok(_) => assert(false)

    var err_seen: Vec[i32] = Vec.new()
    match err_i32("seen").inspect_err(_err => err_seen.push(1)):
        Err(e) => assert(e == "seen")
        Ok(_) => assert(false)
    assert(err_seen.len32() == 1)
    assert(ok_i32(10).inspect_err(_err => unreachable("Result.inspect_err ran on Ok")).unwrap() == 10)

    let piped_step1 = ok_i32(3).and_then(v => double_checked(v))
    let piped_step2 = piped_step1.or_else(e => recover_to_code(e))
    assert(piped_step2.unwrap_or_else(code => code) == 6)

    print("ok")
