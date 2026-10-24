//! expect-error: migrated against LP64 (test model)

// D156 (§16.1, law 10): the diagnostic reads the emitting module's model even
// when another module's C_DATA_MODEL displaced its flat declaration (#1703).
use d156_model

pub const C_DATA_MODEL: str = "the root's model"

fn main:
    print(seam(7))
