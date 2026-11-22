//! expect-error: cannot derive Display for a non-enum type

@[derive(Display)]
type NotAnEnum { value: i32 }

fn main:
    let _ = NotAnEnum { value: 1 }
