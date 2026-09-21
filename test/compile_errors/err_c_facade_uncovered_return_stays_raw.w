//! expect-check-fail: raw c_import function call requires unsafe context

// D51 stage 3: a facade describes db_count but says nothing about db_dup,
// whose pointer return therefore stays raw; coverage is per declaration.

use c_import("typedef struct db db;
db* db_dup(db* d);
int db_count(db* d);
")

c facade dbl:
    fn db_count
        lend

fn main:
    let d = db_dup(null)
    print("unreachable")
