//! expect-error: type 'List[i32]' has no default display; use :? for debug

fn main:
    let v: List[i32] = List.new()
    print(f"{v}")
