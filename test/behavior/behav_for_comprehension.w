//! expect-stdout: ok

fn get_value(x: i32) -> ?i32:
    if x > 0: .Some(x) else: .None

fn double_positive(x: i32) -> ?i32:
    if x > 0: .Some(x * 2) else: .None

fn test_basic:
    let result: ?i32 = for x in get_value(5); y in double_positive(x):
        yield x + y
    assert(result == .Some(15))

fn test_none_first:
    let result: ?i32 = for x in get_value(0 - 1); y in double_positive(1):
        yield x + y
    assert(result == .None)

fn test_none_second:
    let result: ?i32 = for x in get_value(5); y in double_positive(0 - 1):
        yield x + y
    assert(result == .None)

fn main:
    test_basic()
    test_none_first()
    test_none_second()
    print("ok")
