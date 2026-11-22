//! expect-error: strict import omitted

// §16.2: strict completeness turns any unacknowledged omission (here a
// token-paste macro that has no With representation) into a non-zero import
// failure.

use c_import("#define PASTE(a, b) a ## b\nint ok(void);\n", strict: true)

fn main:
    print("x")
