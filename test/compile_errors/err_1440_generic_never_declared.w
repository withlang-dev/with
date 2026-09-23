//! expect-error: unknown type: Missing

// #1440: deferring a generic declared later must still report a generic that
// is never declared, once the declarations have all been collected.
type Holder { g: Missing[i32] }

fn main:
    let h = Holder { g: 0 }
