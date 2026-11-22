//! expect-error: cannot derive Default for type 'UsesNoDefault': field 'value' of type 'NoDefault' does not implement Default

type NoDefault { value: i32 }

@[derive(Default)]
type UsesNoDefault { value: NoDefault }

fn main:
    let _ = UsesNoDefault.default()
