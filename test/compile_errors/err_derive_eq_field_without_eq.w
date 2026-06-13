//! expect-error: cannot derive Eq for type 'UsesNoEq': field 'value' of type 'NoEq' does not implement Eq

type NoEq { value: i32 }

@[derive(Eq)]
type UsesNoEq { value: NoEq }

fn main:
    let _ = UsesNoEq { value: NoEq { value: 1 } }
