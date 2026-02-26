// Phase 4 gap: async block syntax not implemented
fn main -> i32:
    let t = async:
        21 * 2
    let v = t.await
    if v == 42 then 0 else 1
