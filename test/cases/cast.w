fn main -> i32:
    let x: i64 = 1000
    let y = x as i32
    let z: i32 = 42
    let w = z as i64
    assert(w as i32 == 42)
