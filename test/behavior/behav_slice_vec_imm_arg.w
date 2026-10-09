//! expect-stdout: ok

// #604 stage 1: List and array arguments coerce to an immutable []T parameter
// with zero annotation — the first collection→slice call-site coercion.

fn total(xs: []i32) -> i32:
    var s = 0
    for x in xs:
        s = s + x
    s

fn main:
    let a = [1, 2, 3]
    let v: List[i32] = List.new()
    v.push(10)
    v.push(20)
    assert(total(a) == 6)
    assert(total(v) == 30)
    print("ok")
