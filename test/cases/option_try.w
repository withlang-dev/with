fn find_value(x: i32) -> Option[i32]:
    if x > 0 then Some(x)
    else None

fn process -> Option[i32]:
    let val = find_value(42)?
    Some(val)

fn main -> i32:
    let result = process()
    assert(result ?? 0 == 42)
