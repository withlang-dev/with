//! expect-error: no With representation

// §16.2: a token-paste macro has no With representation; referencing it gives
// directional guidance (not just name+reason).

use c_import("#define PASTE(a, b) a##b\n")

fn main:
    PASTE
