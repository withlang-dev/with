//! expect-error: type 'Vec[i32]' has no default display; use :? for debug

fn main:
    let v: Vec[i32] = Vec.new()
    print(f"{v}")
