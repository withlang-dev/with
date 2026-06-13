//! expect-error: cannot derive Hash for type 'UsesNoHash': field 'value' of type 'NoHash' does not implement Hash

type NoHash { value: i32 }

@[derive(Hash)]
type UsesNoHash { value: NoHash }

fn main:
    let _ = UsesNoHash { value: NoHash { value: 1 } }
