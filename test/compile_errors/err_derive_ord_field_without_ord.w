//! expect-error: cannot derive Ord for type 'UsesNoOrd': field 'value' of type 'NoOrd' does not implement Ord

type NoOrd { value: i32 }

@[derive(Ord)]
type UsesNoOrd { value: NoOrd }

fn main:
    let _ = UsesNoOrd { value: NoOrd { value: 1 } }
