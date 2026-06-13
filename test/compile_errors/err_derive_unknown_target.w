//! expect-error: unsupported derive target 'CustomDerive'; expected comptime function 'derive_customDerive[T]() -> str'

@[derive(CustomDerive)]
type NeedsCustomDerive { value: i32 }

fn main:
    let _ = NeedsCustomDerive { value: 1 }
