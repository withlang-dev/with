//! expect-stdout: ok
// Spec test: Section 13.6a — Option and Result For-Comprehensions.

fn get_none -> Option[i32]:
    None

fn fail_result -> Result[i32, str]:
    Err("bad")

fn test_option_comprehension:
    let result = for a in Some(2); b in Some(3):
        yield a + b
    assert(result.unwrap() == 5)

fn test_option_short_circuit:
    let result = for a in Some(2); b in get_none():
        yield a + b
    assert(result.is_none())

fn test_option_guard:
    let result = for x in Some(4); if x > 0:
        yield x * 2
    assert(result.unwrap() == 8)

    let filtered = for x in Some(4); if x < 0:
        yield x * 2
    assert(filtered.is_none())

fn test_result_comprehension:
    let result: Result[i32, str] =
        for a in Ok(2); b in Ok(3):
            yield a + b
    assert(result.unwrap() == 5)

fn test_result_short_circuit:
    let result: Result[i32, str] =
        for a in Ok(2); b in fail_result():
            yield a + b
    assert(result.is_err())

fn test_statement_form:
    var got = 0
    for a in Some(2); b in Some(3):
        got = a + b
    assert(got == 5)

    for a in Some(2); b in get_none():
        got = 99
    assert(got == 5)

fn main:
    test_option_comprehension()
    test_option_short_circuit()
    test_option_guard()
    test_result_comprehension()
    test_result_short_circuit()
    test_statement_form()
    print("ok")
