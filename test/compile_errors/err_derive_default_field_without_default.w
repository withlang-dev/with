//! expect-error: unknown method 'default'

type NoDefault { value: i32 }

@[derive(Default)]
type UsesNoDefault { value: NoDefault }

fn main:
    let _ = UsesNoDefault.default()
