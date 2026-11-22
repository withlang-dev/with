//! expect-error: cannot infer type parameter 'T' for this call; annotate the result binding or pass an argument that mentions 'T'

// §13.3 (#2943): `Iter.empty()` is std's constructor; with nothing to bind
// its element type, the call says what would bind it.
fn main:
    let _ = Iter.empty()
