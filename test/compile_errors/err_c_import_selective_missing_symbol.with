//! expect-error: c_import: requested symbol

// §16.2: a selectively-imported symbol that the header does not provide is a
// loud failure, never a silent empty import.

use c_import("int present(void);\n", only: ["absent"])

fn main:
    print("x")
