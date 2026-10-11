// &T parameter: read-only access, no mutation, caller's value unchanged.

fn read_i32(x: &i32) -> i32:
    return *x

fn sum_coords(x: &i32, y: &i32) -> i32:
    return *x + *y

fn main:
    let n: i32 = 42
    let m: i32 = 8
    let v = read_i32(&n)
    assert(v == 42)
    assert(n == 42)   // original unchanged
    let s = sum_coords(&n, &m)
    assert(s == 50)
    print("ok\n")
