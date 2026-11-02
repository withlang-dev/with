//! expect-build-stderr: migrated against LP64 (test model)
//! expect-stdout: 7
// D156 (§16.1, law 10): the narrowing lint reads the emitting module's model
// even when another module's C_DATA_MODEL displaced its flat declaration
// (#1703). Under D183 the narrowing is a checked conversion, so the seam
// is a warning on the build, not a refusal.
use lib.d156_model

pub const C_DATA_MODEL: str = "the root's model"

fn main:
    print(seam(7))
