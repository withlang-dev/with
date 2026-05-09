//! expect-error: @[specified] requires a discriminant enum with an explicit backing type

@[specified]
enum Mode { Read | Write }

fn main:
    let _ = Mode.Read
