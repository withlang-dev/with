//! expect-stdout: ok

// D115 (§9.7): `rest` names the remaining elements, and its length is
// `rest.len()`.
fn main:
    let arr = [1, 2, 3]
    match arr:
        [first, ..rest] =>
            assert(first == 1)
            assert(rest.len() == 2)
            assert(rest[1] == 3)
        _ => assert(false)

    let arr2 = [1, 2, 3, 4]
    match arr2:
        [first, ..mid, last] =>
            assert(first == 1)
            assert(mid.len() == 2)
            assert(mid[0] == 2)
            assert(last == 4)
        _ => assert(false)

    print("ok")
