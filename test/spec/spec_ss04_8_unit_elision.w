// Spec test: Section 4.8 — Unit Elision.

fn do_work -> Result[Unit, str]: Ok()

fn do_work_explicit -> Result[Unit, str]: Ok(())

fn takes_unit(value: Unit):
    ()

fn test_ok_unit_elision:
    assert(do_work().is_ok())
    assert(do_work_explicit().is_ok())

fn test_function_unit_elision:
    takes_unit()
    takes_unit(())

fn test_result_unwrap_or_unit_elision:
    let r: Result[Unit, str] = Err("fail")
    r.unwrap_or()

fn test_unit_elision_in_match:
    let r: Result[Unit, str] = Ok()
    match r:
        Ok() => assert(true)
        Err(_) => assert(false)

fn test_no_elision_when_payload_is_not_unit:
    let r: Result[i32, str] = Ok(42)
    assert(r.unwrap_or(0) == 42)
