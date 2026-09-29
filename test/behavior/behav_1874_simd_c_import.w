//! expect-stdout: layout 32 16 16 | 32 16 16 | v8f align true
//! expect-stdout: wide true true
//! expect-stdout: scale 2 4 6 8
//! expect-stdout: add 5 7 9
//! expect-stdout: sum 42
//! expect-stdout: wide lane 16
//! expect-stdout: bytes 16

// §16.1 (D78, #1874): a `vector_size` or `ext_vector_type` type imports as
// `Vector[N, T]` — the alias for the native widths — with C's layout
// (including a record holding a vector over 16 bytes, whose alignment is
// the target's), and a C function that takes or returns one is callable.
use c_import("behav_1874_simd_c_import.h")

fn main:
    print(f"layout {size_of[with_vertex]()} {align_of[with_vertex]()} {size_of[with_v3f]()} | {WITH_VERTEX_SIZE} {WITH_VERTEX_ALIGN} {WITH_V3F_SIZE} | v8f align {align_of[with_v8f]() == WITH_V8F_ALIGN}")
    print(f"wide {size_of[with_wide]() == WITH_WIDE_SIZE} {align_of[with_wide]() == WITH_WIDE_ALIGN}")
    let v: f32x4 = with_v4f_scale(f32x4(1, 2, 3, 4), 2.0f32)
    print(f"scale {v[0] as i32} {v[1] as i32} {v[2] as i32} {v[3] as i32}")
    let a: Vector[3, f32] = with_v3f_add(Vector[3, f32](1, 2, 3), Vector[3, f32](4, 5, 6))
    print(f"add {a[0] as i32} {a[1] as i32} {a[2] as i32}")
    print(f"sum {with_v2ll_sum(i64x2(40, 2))}")
    let w = with_wide { tag: 1, wide: f32x8(0, 1, 2, 3, 4, 5, 6, 7), tail: 11 }
    print(f"wide lane {with_wide_lane(w) as i32}")
    let b: with_v16u8 = u8x16.splat(7)
    print(f"bytes {size_of[with_v16u8]()}")
    let _ = b
