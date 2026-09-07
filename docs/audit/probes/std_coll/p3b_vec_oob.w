// Probe p3b: Vec get out-of-bounds — expect LOUD panic (T23).
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    let x: i32 = v.get(99)
    print("SHOULD-NOT-PRINT")
