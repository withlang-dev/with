//! expect-stdout: ok

fn pair(a: i32, b: i32) -> (i32, i32):
    (a, b)

fn pair_with_default(a: i32, b: i32 = 10) -> (i32, i32):
    (a, b)

fn test_tuple_return_destructure:
    let (x, y) = pair(3, 4)
    assert(x == 3)
    assert(y == 4)

fn test_tuple_return_with_default:
    let (x, y) = pair_with_default(5)
    assert(x == 5)
    assert(y == 10)

fn test_tuple_return_named_args:
    let (x, y) = pair(b: 20, a: 10)
    assert(x == 10)
    assert(y == 20)

fn test_tuple_wildcard:
    let (_, y) = pair(1, 2)
    assert(y == 2)

fn main:
    test_tuple_return_destructure()
    test_tuple_return_with_default()
    test_tuple_return_named_args()
    test_tuple_wildcard()
    print("ok")
