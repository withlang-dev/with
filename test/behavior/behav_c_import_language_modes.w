//! expect-stdout: 1 2 4

// Identical source with different languages must not share an import cache.
// The omitted language and explicit C mode keep the same declaration surface.
use c_import("behav_c_import_language_modes.h")
use c_import("behav_c_import_language_modes.h", lang: "c")
use c_import("behav_c_import_language_modes.h", lang: "c++")

fn main: print(f"{FLAT_C_MODE} {FLAT_CXX_MODE} {size_of[FlatPlain]()}")
