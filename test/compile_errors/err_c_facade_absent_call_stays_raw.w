//! expect-check-fail: raw c_import function call requires unsafe context

// D51 stage 3 guard: the same call that a facade makes safe
// (behav/parser twin: c_facade_lend_call_needs_no_unsafe) stays raw without
// one — nothing is inferred from a name (ruling §60).

use c_import("typedef struct db db;\nint db_open(const char* path, db** out);\nvoid db_close(db* d);\nint db_count(db* d);\n")

fn main:
    let n = db_count(null)
    print(f"{n}")
