// Spec test: Section 10.3, 10.4 — Option/Result Combinators (formerly 25.22)

// PASS: option chaining
fn test_option_map_some:
    let x: Option[i32] = Some(5)
    let y = x.map(n => n * 2).unwrap_or(0)
    assert(y == 10)

// PASS: and_then chains
fn test_option_filter_and_then_some:
    let result = Some(10).filter(x => x > 5).and_then(x => if x < 20: Some(x) else: None).unwrap_or(0)
    assert(result == 10)

fn test_option_and_then_none:
    let x: Option[i32] = None
    let y = x.and_then(n => Some(n * 2)).unwrap_or(9)
    assert(y == 9)

// PASS: result map_err
fn test_result_map_err:
    let r: Result[i32, str] = Err("bad")
    let r2: Result[i32, usize] = r.map_err(s => s.len())
    match r2:
        Err(n) => assert(n == 3)
        Ok(_) => assert(false)

fn test_result_map_err_preserves_ok:
    let r: Result[i32, str] = Ok(7)
    let r2: Result[i32, usize] = r.map_err(s => s.len())
    assert(r2.unwrap() == 7)

// PASS: result map
fn test_result_map_ok:
    let r: Result[i32, str] = Ok(5)
    let r2: Result[i32, str] = r.map(n => n * 2)
    assert(r2.unwrap() == 10)

fn test_result_map_preserves_err:
    let r: Result[i32, str] = Err("bad")
    let r2: Result[i32, str] = r.map(n => n * 2)
    match r2:
        Err(s) => assert(s == "bad")
        Ok(_) => assert(false)

// PASS: option on None
fn test_option_map_none:
    let x: Option[i32] = None
    let y = x.map(n => n * 2).unwrap_or(42)
    assert(y == 42)
