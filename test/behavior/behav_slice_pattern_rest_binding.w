//! expect-stdout: ok

fn main:
    let arr = [1, 2, 3]
    match arr:
        [first, ..rest] =>
            assert(first == 1)
            assert(rest == 2)
        _ => assert(false)

    let arr2 = [1, 2, 3, 4]
    match arr2:
        [first, ..mid, last] =>
            assert(first == 1)
            assert(mid == 2)
            assert(last == 4)
        _ => assert(false)

    print("ok")
