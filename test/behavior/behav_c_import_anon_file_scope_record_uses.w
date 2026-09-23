//! check-only

// #1396: the declarations that use a file-scope record with no tag and no
// typedef name carry its synthesized name: variables (arrays and pointers
// too), a function's result and parameter, and a typedef reaching it through
// a pointer. Check-only: the header's globals and functions have no
// definition to link against.

use c_import("behav_c_import_anon_file_scope_record.h")

fn reads -> i64:
    let g1: anon_g1_anon = anon_g1
    let g3: anon_g3_anon = anon_g3[1]
    let a: anon_a_anon = anon_a
    let b: anon_a_anon = anon_b
    let u: anon_gu_anon = anon_gu
    let n: anon_gn_anon = anon_gn
    let made: anon_mk_return_anon = anon_mk()
    let p: *mut anon_gp_anon = anon_gp
    let px: *mut anon_px_t_anon = 0 as anon_px_t
    var q = anon_take_p_anon { q: 1 }
    unsafe { anon_take(&raw mut q) }
    let z: anon_gz_anon_2 = anon_gz
    (g1.b + g3.d + a.f + b.f + n.w + sizeof[anon_gu_anon]() as i32 + made.r + z.k as i32) as i64 + g3.e + (p as i64) + (px as i64)

fn main:
    print(f"{reads()}")
