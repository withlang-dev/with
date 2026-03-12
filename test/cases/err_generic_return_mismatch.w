//! expect-error: return type mismatch
fn get_vec() -> Vec[i32]:
    let v: Vec[str] = Vec.new()
    v
