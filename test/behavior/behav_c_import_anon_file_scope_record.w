//! expect-stdout: ok

// #1396: a file-scope struct/union with no tag and no typedef name imports
// under a name synthesized from the first declarator that uses it, and every
// declaration that uses it spells that name: the layouts below are C's.
// The C_ASSERT record in the header, which nothing uses, is not emitted; the
// import used to fail to parse on `type struct (unnamed at ...)`.

use c_import("behav_c_import_anon_file_scope_record.h")

fn main:
    let one = anon_g1_anon { b: 7 }
    assert(one.b == 7)
    assert(sizeof[anon_g2_anon]() == 4)
    let three = anon_g3_anon { d: 1, e: 2 }
    assert(three.e == 2)
    assert(sizeof[anon_g3_anon]() == 16)
    assert(sizeof[anon_a_anon]() == 4)
    assert(sizeof[anon_gu_anon]() == 4)
    assert(ANON_EB == 2)
    let nested = anon_gn_anon { inner: anon_gn_anon_inner { x: 5 }, anon_1: anon_gn_anon_anon_1 { y: 6 }, w: 7 }
    assert(nested.inner.x == 5)
    assert(nested.w == 7)
    assert(sizeof[anon_gn_anon]() == 12)
    assert(sizeof[anon_mk_return_anon]() == 8)
    assert(sizeof[anon_take_p_anon]() == 4)
    assert(sizeof[anon_px_t_anon]() == 4)
    assert(sizeof[anon_gp_anon]() == 4)
    assert(sizeof[anon_gz_anon_2]() == 1)
    let z: anon_gz_anon = 9
    assert(z == 9)
    assert(anon_k.lo == 3)
    assert(anon_k.hi == 4)
    print("ok")
