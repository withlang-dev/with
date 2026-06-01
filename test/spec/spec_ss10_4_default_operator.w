fn test_basic_default_operator:
    let x: Option[i32] = None
    let y = x ?? 42
    assert(y == 42)

fn test_chained_default_operator:
    let a: Option[i32] = None
    let b: Option[i32] = None
    let c: Option[i32] = Some(3)
    let result = a ?? b ?? c ?? 0
    assert(result == 3)

// PASS: default with early return
fn find(id: i32) -> Option[str]: None
fn get_or_fail(id: i32) -> Result[str, str]:
    let name = find(id) ?? return Err("not found")
    Ok(name)

fn test_default_operator_with_early_return:
    assert(get_or_fail(1).is_err())
