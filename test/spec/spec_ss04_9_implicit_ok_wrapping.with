// Spec test: Section 4.9 — Implicit Ok Wrapping.

fn get_number -> Result[i32, str]:
    42

fn do_stuff -> Result[Unit, str]:
    let x = 1

fn explicit -> Result[i32, str]:
    Ok(42)

fn fail -> Result[i32, str]:
    Err("nope")

fn read_ok -> Result[i32, str]:
    41

fn read_err -> Result[i32, str]:
    Err("bad")

fn chain_ok -> Result[i32, str]:
    let value = read_ok()?
    value + 1

fn chain_err -> Result[i32, str]:
    let value = read_err()?
    value + 1

fn already_result -> Result[i32, str]:
    Ok(7)

fn default_i32 -> Result[i32, str]:
    let x = 1

fn test_value_auto_wrapped:
    assert(get_number().unwrap() == 42)

fn test_result_unit_empty_tail:
    assert(do_stuff().is_ok())

fn test_explicit_result_variants_still_work:
    assert(explicit().unwrap() == 42)
    assert(fail().is_err())

fn test_question_propagates_and_tail_wraps:
    assert(chain_ok().unwrap() == 42)
    assert(chain_err().is_err())

fn test_existing_result_not_double_wrapped:
    assert(already_result().unwrap() == 7)

fn test_defaultable_empty_tail_wraps_default:
    assert(default_i32().unwrap() == 0)
