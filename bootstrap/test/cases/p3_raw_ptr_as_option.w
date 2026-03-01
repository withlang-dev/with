// Phase 3 gap: raw pointer .as_option() codegen path not complete
use c_import("stdlib.h")

fn main -> i32:
    let p = malloc(8)
    let o = p.as_option()
    if o.is_none() then return 1
    free(p)
    0
