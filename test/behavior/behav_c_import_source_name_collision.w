//! expect-stdout: 2
// A header import does not replace a different module's function signature.
use c_import("time.h", only: ["clock"])
use fixtures.c_import_source_name_collision_module

fn main:
    print(formatted_minutes(120))
