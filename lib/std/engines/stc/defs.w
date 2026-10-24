// std.engines.stc.defs — shared definitions for migrated PCRE2
use std.option
use std.collections
use rt.rt_core

pub fn is_alpha(__with_c: i32) -> bool {
    (__with_c >= 65 and __with_c <= 90) or (__with_c >= 97 and __with_c <= 122)
}
pub fn is_digit(__with_c: i32) -> bool {
    __with_c >= 48 and __with_c <= 57
}
pub fn is_space(__with_c: i32) -> bool {
    __with_c == 32 or __with_c == 9 or __with_c == 10 or __with_c == 13 or __with_c == 12 or __with_c == 11
}
pub fn is_alnum(__with_c: i32) -> bool {
    is_alpha(__with_c) or is_digit(__with_c)
}
pub fn is_upper(__with_c: i32) -> bool {
    __with_c >= 65 and __with_c <= 90
}
pub fn is_lower(__with_c: i32) -> bool {
    __with_c >= 97 and __with_c <= 122
}
pub fn is_xdigit(__with_c: i32) -> bool {
    (__with_c >= 48 and __with_c <= 57) or (__with_c >= 65 and __with_c <= 70) or (__with_c >= 97 and __with_c <= 102)
}
pub fn is_print(__with_c: i32) -> bool {
    __with_c >= 32 and __with_c <= 126
}
pub fn to_lower(__with_c: i32) -> i32 {
    if __with_c >= 65 and __with_c <= 90 { __with_c + 32 } else { __with_c }
}
pub fn to_upper(__with_c: i32) -> i32 {
    if __with_c >= 97 and __with_c <= 122 { __with_c - 32 } else { __with_c }
}
pub extern fn strlen(s: *const c_char) -> u64
pub extern fn strcmp(a: *const c_char, b: *const c_char) -> i32
pub extern fn strncmp(a: *const c_char, b: *const c_char, n: i64) -> i32
pub extern fn strchr(s: *const c_char, c: i32) -> *mut c_char
pub extern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void
pub extern fn isalpha(c: i32) -> i32
pub extern fn isdigit(c: i32) -> i32
pub extern fn isalnum(c: i32) -> i32
pub extern fn isspace(c: i32) -> i32
pub extern fn isupper(c: i32) -> i32
pub extern fn islower(c: i32) -> i32
pub extern fn isxdigit(c: i32) -> i32
pub extern fn isprint(c: i32) -> i32
pub extern fn isgraph(c: i32) -> i32
pub extern fn ispunct(c: i32) -> i32
pub extern fn iscntrl(c: i32) -> i32
pub extern fn tolower(c: i32) -> i32
pub extern fn toupper(c: i32) -> i32
pub extern fn sqrt(x: f64) -> f64
pub extern fn pow(base: f64, exp: f64) -> f64
pub extern fn floor(x: f64) -> f64
pub extern fn ceil(x: f64) -> f64
pub extern fn round(x: f64) -> f64
pub extern fn sin(x: f64) -> f64
pub extern fn cos(x: f64) -> f64
pub extern fn tan(x: f64) -> f64
pub extern fn log(x: f64) -> f64
pub extern fn log10(x: f64) -> f64
pub extern fn exp(x: f64) -> f64
pub extern fn fabs(x: f64) -> f64
pub extern fn fmod(x: f64, y: f64) -> f64
pub extern fn asin(x: f64) -> f64
pub extern fn acos(x: f64) -> f64
pub extern fn atan(x: f64) -> f64
pub extern fn atan2(y: f64, x: f64) -> f64

pub type c_void = opaque
pub extern fn abort() -> Never
pub fn __ci_unreachable() -> Never: abort()

// data model: LP64 (arm64-apple-macosx11.0)
pub const C_DATA_MODEL: str = "LP64 (arm64-apple-macosx11.0)"
pub unsafe fn __with_builtin_add_overflow_i8(__with_a: i8, __with_b: i8, __with_out: *mut i8) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i8(__with_a: i8, __with_b: i8, __with_out: *mut i8) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i8(__with_a: i8, __with_b: i8, __with_out: *mut i8) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u8(__with_a: u8, __with_b: u8, __with_out: *mut u8) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u8(__with_a: u8, __with_b: u8, __with_out: *mut u8) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u8(__with_a: u8, __with_b: u8, __with_out: *mut u8) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i16(__with_a: i16, __with_b: i16, __with_out: *mut i16) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i16(__with_a: i16, __with_b: i16, __with_out: *mut i16) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i16(__with_a: i16, __with_b: i16, __with_out: *mut i16) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u16(__with_a: u16, __with_b: u16, __with_out: *mut u16) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u16(__with_a: u16, __with_b: u16, __with_out: *mut u16) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u16(__with_a: u16, __with_b: u16, __with_out: *mut u16) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i32(__with_a: i32, __with_b: i32, __with_out: *mut i32) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i32(__with_a: i32, __with_b: i32, __with_out: *mut i32) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i32(__with_a: i32, __with_b: i32, __with_out: *mut i32) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u32(__with_a: u32, __with_b: u32, __with_out: *mut u32) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u32(__with_a: u32, __with_b: u32, __with_out: *mut u32) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u32(__with_a: u32, __with_b: u32, __with_out: *mut u32) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i64(__with_a: i64, __with_b: i64, __with_out: *mut i64) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i64(__with_a: i64, __with_b: i64, __with_out: *mut i64) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i64(__with_a: i64, __with_b: i64, __with_out: *mut i64) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_a == 0 or __with_b == 0: false else if __with_a == -1: __with_result == __with_b else if __with_b == -1: __with_result == __with_a else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_u64(__with_a: u64, __with_b: u64, __with_out: *mut u64) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u64(__with_a: u64, __with_b: u64, __with_out: *mut u64) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u64(__with_a: u64, __with_b: u64, __with_out: *mut u64) -> bool {
    let __with_result = __with_a *% __with_b
    unsafe { (*__with_out = __with_result) }
    if __with_b == 0: false else: __with_result / __with_b != __with_a
}
pub unsafe fn __with_builtin_add_overflow_i128(__with_a: i128, __with_b: i128, __with_out: *mut i128) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_result ^ __with_a) & (__with_result ^ __with_b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i128(__with_a: i128, __with_b: i128, __with_out: *mut i128) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    ((__with_a ^ __with_b) & (__with_result ^ __with_a)) < 0
}
// The 128-bit overflow checks stay division-free on purpose: `/` on i128/u128
// lowers to the __divti3/__udivti3 compiler-rt libcalls, and this shim is
// compiled into freestanding runtime objects whose COFF link has no builtins
// library to resolve them from. Limb decomposition keeps the check to multiplies
// and shifts, which lower inline on every target and at every -O level.
pub fn u128_mul_would_overflow(__with_a: u128, __with_b: u128) -> bool {
    let __with_a_hi = (__with_a >> 64) as u64
    let __with_b_hi = (__with_b >> 64) as u64
    if __with_a_hi != 0 and __with_b_hi != 0: return true
    let __with_a_lo = (__with_a as u64) as u128
    let __with_b_lo = (__with_b as u64) as u128
    let __with_cross = (__with_a_hi as u128) *% __with_b_lo +% (__with_b_hi as u128) *% __with_a_lo
    if (__with_cross >> 64) != 0: return true
    let __with_low = __with_a_lo *% __with_b_lo
    ((__with_low >> 64) +% __with_cross) >> 64 != 0
}
pub unsafe fn __with_builtin_mul_overflow_i128(__with_a: i128, __with_b: i128, __with_out: *mut i128) -> bool {
    unsafe { (*__with_out = __with_a *% __with_b) }
    if __with_a == 0 or __with_b == 0: return false
    let __with_neg = (__with_a < 0) != (__with_b < 0)
    let __with_ua = if __with_a < 0: (0 as u128) -% (__with_a as u128) else: __with_a as u128
    let __with_ub = if __with_b < 0: (0 as u128) -% (__with_b as u128) else: __with_b as u128
    if u128_mul_would_overflow(__with_ua, __with_ub): return true
    let __with_limit = if __with_neg: (1 as u128) << 127 else: ((1 as u128) << 127) -% 1
    __with_ua *% __with_ub > __with_limit
}
pub unsafe fn __with_builtin_add_overflow_u128(__with_a: u128, __with_b: u128, __with_out: *mut u128) -> bool {
    let __with_result = __with_a +% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_result < __with_a
}
pub unsafe fn __with_builtin_sub_overflow_u128(__with_a: u128, __with_b: u128, __with_out: *mut u128) -> bool {
    let __with_result = __with_a -% __with_b
    unsafe { (*__with_out = __with_result) }
    __with_a < __with_b
}
pub unsafe fn __with_builtin_mul_overflow_u128(__with_a: u128, __with_b: u128, __with_out: *mut u128) -> bool {
    unsafe { (*__with_out = __with_a *% __with_b) }
    u128_mul_would_overflow(__with_a, __with_b)
}

pub type isize_t = i64

pub type isize_ = i64

pub type _istride = i32

pub type _ituple3 = [i32; 3]

@[repr(C)]
pub type cspan_tuple1 { pub d: [i32; 1] = [0 as i32; 1] }
impl Copy for cspan_tuple1

@[repr(C)]
pub type cspan_tuple2 { pub d: [i32; 2] = [0 as i32; 2] }
impl Copy for cspan_tuple2

@[repr(C)]
pub type cspan_tuple3 { pub d: [i32; 3] = [0 as i32; 3] }
impl Copy for cspan_tuple3

@[repr(C)]
pub type cspan_tuple4 { pub d: [i32; 4] = [0 as i32; 4] }
impl Copy for cspan_tuple4

@[repr(C)]
pub type cspan_tuple5 { pub d: [i32; 5] = [0 as i32; 5] }
impl Copy for cspan_tuple5

@[repr(C)]
pub type cspan_tuple6 { pub d: [i32; 6] = [0 as i32; 6] }
impl Copy for cspan_tuple6

@[repr(C)]
pub type cspan_tuple7 { pub d: [i32; 7] = [0 as i32; 7] }
impl Copy for cspan_tuple7

@[repr(C)]
pub type cspan_tuple8 { pub d: [i32; 8] = [0 as i32; 8] }
impl Copy for cspan_tuple8

pub type cspan_layout = i32

pub let c_ROWMAJOR: i32 = 0
pub let c_COLMAJOR: i32 = 1
pub let c_STRIDED: i32 = 2
pub let ISIZE_MIN: i64 = (0 - 9223372036854775807 - 1)
pub let ISIZE_MAX: i64 = 9223372036854775807
pub let c_ZI: [c_char; 3] = [108, 105, 0]
pub let c_ZU: [c_char; 3] = [108, 117, 0]
pub let c_NPOS: i64 = 9223372036854775807
pub fn c_literal[T](p_T: T) -> T {
    p_T
}
pub fn c_countof[T](a: T) -> i64 {
    (sizeof[T]() as i64)
}
pub fn c_strlen[T](s: T) -> i64 {
    (strlen(s) as i64)
}
pub fn c_u2i_cast[T](u: T) -> i64 {
    ((if 1 != 0: u else: (1 as usize)) as i64)
}
pub fn c_i2u_cast[T](i: T) -> usize {
    ((if 1 != 0: i else: -1) as usize)
}
pub fn c_uless[T](a: T, b: T) -> i32 {
    (((a as usize) < (b as usize)) as i32)
}
pub fn c_default_eq[T](x: T, y: T) -> i32 {
    (((unsafe *x) == (unsafe *y)) as i32)
}
pub fn c_default_less[T](x: T, y: T) -> i32 {
    (((unsafe *x) < (unsafe *y)) as i32)
}
pub fn c_default_cmp[T](x: T, y: T) -> T {
    (c_default_less(y, x) - c_default_less(x, y))
}
pub fn c_default_clone[T](v: T) -> T {
    v
}
pub fn c_default_toraw[T](vp: T) -> T {
    (unsafe *vp)
}
pub fn c_default_drop[T](vp: T) -> T {
    vp
}
pub fn c_arraylen[T](a: T) -> i64 {
    c_countof(a)
}
pub let FNV_BASIS: u64 = 0xcbf29ce484222325
pub let FNV_PRIME: i64 = 0x00000100000001b3
pub let c_END: i32 = 2147483647
@[repr(C)]
pub type cutf8_decode_t { pub state: u32 = 0, pub codep: u32 = 0 }
impl Copy for cutf8_decode_t

pub type csview_value = c_char

@[repr(C)]
pub type csview { pub buf: *mut c_char = null, pub size: i64 = 0 }
impl Copy for csview

@[repr(C)]
pub type csview_iter_u8 { chr: csview, end: *mut c_char = null, dec: cutf8_decode_t }
impl Copy for csview_iter_u8
@[repr(C)]
pub type csview_iter = union { pub u8: csview_iter_u8, pub chr: csview, pub ref: *mut c_char = null }
impl Copy for csview_iter

pub type zsview_value = c_char

@[repr(C)]
pub type zsview { pub str: *mut c_char = null, pub size: i64 = 0 }
impl Copy for zsview

@[repr(C)]
pub type zsview_iter_u8 { chr: csview, dec: cutf8_decode_t }
impl Copy for zsview_iter_u8
@[repr(C)]
pub type zsview_iter = union { pub u8: zsview_iter_u8, pub chr: csview, pub ref: *mut c_char = null }
impl Copy for zsview_iter

pub type cstr_value = c_char

@[repr(C)]
pub type cstr_buf { pub data: *mut c_char = null, pub size: i64 = 0, pub cap: i64 = 0 }
impl Copy for cstr_buf

@[repr(C)]
pub type cstr_sml { data: [c_char; 23] = [0 as c_char; 23], size: u8 = 0 }
impl Copy for cstr_sml
@[repr(C)]
pub type cstr_lon { data: *mut c_char = null, size: u64 = 0, ncap: u64 = 0 }
impl Copy for cstr_lon
@[repr(C)]
pub type cstr = union { pub sml: cstr_sml, pub lon: cstr_lon }
impl Copy for cstr

@[repr(C)]
pub type cstr_iter_u8 { chr: csview, dec: cutf8_decode_t }
impl Copy for cstr_iter_u8
@[repr(C)]
pub type cstr_iter = union { pub u8: cstr_iter_u8, pub chr: csview, pub ref: *const c_char = null }
impl Copy for cstr_iter

pub type cstr_raw = *const c_char

pub let cutf8_ACCEPT: i32 = 0
pub let cutf8_REJECT: i32 = 12
pub type cutf8_group = i32

pub let U8G_Cc: i32 = 0
pub let U8G_L: i32 = 1
pub let U8G_Lm: i32 = 2
pub let U8G_Lt: i32 = 3
pub let U8G_Nd: i32 = 4
pub let U8G_Nl: i32 = 5
pub let U8G_No: i32 = 6
pub let U8G_P: i32 = 7
pub let U8G_Pc: i32 = 8
pub let U8G_Pd: i32 = 9
pub let U8G_Pe: i32 = 10
pub let U8G_Pf: i32 = 11
pub let U8G_Pi: i32 = 12
pub let U8G_Ps: i32 = 13
pub let U8G_Sc: i32 = 14
pub let U8G_Sk: i32 = 15
pub let U8G_Sm: i32 = 16
pub let U8G_Zl: i32 = 17
pub let U8G_Zp: i32 = 18
pub let U8G_Zs: i32 = 19
pub let U8G_Arabic: i32 = 20
pub let U8G_Bengali: i32 = 21
pub let U8G_Cyrillic: i32 = 22
pub let U8G_Devanagari: i32 = 23
pub let U8G_Georgian: i32 = 24
pub let U8G_Greek: i32 = 25
pub let U8G_Han: i32 = 26
pub let U8G_Hiragana: i32 = 27
pub let U8G_Katakana: i32 = 28
pub let U8G_Latin: i32 = 29
pub let U8G_Thai: i32 = 30
pub let U8G_SIZE: i32 = 31
pub let cstr_s_cap: i32 = 22
pub let c_svfmt = "%.*s"
pub fn cstr_raw_cmp[T](x: T, y: T) -> i32 {
    strcmp((unsafe *x), (unsafe *y))
}
pub fn cstr_raw_eq[T](x: T, y: T) -> i32 {
    ((cstr_raw_cmp(x, y) == 0) as i32)
}
pub fn cstr_raw_hash[T](vp: T) -> T {
    unsafe { c_hash_str((unsafe *vp)) }
}
@[repr(C)]
pub type CaseMapping { pub c1: u16 = 0, pub c2: u16 = 0, pub m2: u16 = 0 }
impl Copy for CaseMapping

pub let casefold_len: i32 = 192
@[repr(C)]
pub type fn_tocase_anon { pub conv_asc: Option[extern "C" fn(i32) -> i32] = null, pub conv_utf: Option[extern "C" fn(u32) -> u32] = null }
impl Copy for fn_tocase_anon

@[repr(C)]
pub type stc_slot_head { pub cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> i32] = null, pub hash: Option[unsafe extern "C" fn(*const c_void) -> u64] = null }
impl Copy for stc_slot_head

pub type stc_slot = *mut stc_slot_head

@[repr(C)]
pub type hmap_meta { pub __bits_0: u16 = 0 }
impl Copy for hmap_meta
impl hmap_meta:
    pub fn hashx() -> u16: ((self.__bits_0 >> 0) & 63) as u16
    pub mut fn set_hashx(v: u16): self.__bits_0 = (self.__bits_0 & ~((63 as u16) << 0)) | (((v as u16) & 63) << 0)
    pub fn dist() -> u16: ((self.__bits_0 >> 6) & 1023) as u16
    pub mut fn set_dist(v: u16): self.__bits_0 = (self.__bits_0 & ~((1023 as u16) << 6)) | (((v as u16) & 1023) << 6)
comptime fn __ci_layout_hmap_meta() -> Unit:
    if sizeof[*const u8]() == 8 and (sizeof[hmap_meta]() != 2 or offsetof[hmap_meta](__bits_0) != 0): comptime_error("hmap_meta: the bitfield layout this migration recorded (D147) differs on this target")
const __ci_layout_hmap_meta_check: Unit = __ci_layout_hmap_meta()

pub type stc_slot_set_key = *mut stc_slot_head

pub type stc_slot_set_mapped = *mut stc_slot_head

pub type stc_slot_set_value = *mut stc_slot_head

pub type stc_slot_set_entry = *mut stc_slot_head

@[repr(C)]
pub type stc_slot_set_result { pub ref: *mut *mut stc_slot_head = null, pub idx: u64 = 0, pub inserted: bool = false, pub hashx: u8 = 0, pub dist: u16 = 0 }
impl Copy for stc_slot_set_result

@[repr(C)]
pub type stc_slot_set_iter { pub ref: *mut *mut stc_slot_head = null, pub _end: *mut *mut stc_slot_head = null, pub _mref: *mut hmap_meta = null }
impl Copy for stc_slot_set_iter

@[repr(C)]
pub type stc_slot_set { pub table: *mut *mut stc_slot_head = null, pub meta: *mut hmap_meta = null, pub size: i64 = 0, pub bucket_count: i64 = 0 }
impl Copy for stc_slot_set

pub type stc_slot_set_keyraw = *mut stc_slot_head

pub type stc_slot_set_rmapped = *mut stc_slot_head

pub type stc_slot_set_raw = *mut stc_slot_head

pub type stc_slot_sset_key = *mut stc_slot_head

pub type stc_slot_sset_mapped = *mut stc_slot_head

pub type stc_slot_sset_value = *mut stc_slot_head

pub type stc_slot_sset_entry = *mut stc_slot_head

@[repr(C)]
pub type stc_slot_sset_result { pub ref: *mut *mut stc_slot_head = null, pub inserted: bool = false }
impl Copy for stc_slot_sset_result

@[repr(C)]
pub type stc_slot_sset_iter { pub ref: *mut *mut stc_slot_head = null, pub _d: *mut stc_slot_sset_node = null, pub _top: i32 = 0, pub _tn: i32 = 0, pub _st: [i32; 36] = [0 as i32; 36] }
impl Copy for stc_slot_sset_iter

@[repr(C)]
pub type stc_slot_sset { pub nodes: *mut stc_slot_sset_node = null, pub root: i32 = 0, pub disp: i32 = 0, pub head: i32 = 0, pub size: i32 = 0, pub capacity: i32 = 0 }
impl Copy for stc_slot_sset

@[repr(C)]
pub type stc_slot_sset_node { pub link: [i32; 2] = [0 as i32; 2], pub level: i8 = 0, pub value: *mut stc_slot_head = null }
impl Copy for stc_slot_sset_node

pub type stc_slot_sset_keyraw = *mut stc_slot_head

pub type stc_slot_sset_rmapped = *mut stc_slot_head

pub type stc_slot_sset_raw = *mut stc_slot_head

pub type stc_slot_pqueue_value = *mut stc_slot_head

@[repr(C)]
pub type stc_slot_pqueue_iter { pub ref: *mut *mut stc_slot_head = null, pub end: *mut *mut stc_slot_head = null }
impl Copy for stc_slot_pqueue_iter

@[repr(C)]
pub type stc_slot_pqueue { pub data: *mut *mut stc_slot_head = null, pub size: i64 = 0, pub capacity: i64 = 0 }
impl Copy for stc_slot_pqueue

pub type stc_slot_pqueue_raw = *mut stc_slot_head

pub type stc_slot_deque_value = *mut stc_slot_head

@[repr(C)]
pub type stc_slot_deque { pub cbuf: *mut *mut stc_slot_head = null, pub start: i64 = 0, pub end: i64 = 0, pub capmask: i64 = 0 }
impl Copy for stc_slot_deque

@[repr(C)]
pub type stc_slot_deque_iter { pub ref: *mut *mut stc_slot_head = null, pub pos: i64 = 0, pub _s: *const stc_slot_deque = null }
impl Copy for stc_slot_deque_iter

pub type stc_slot_deque_raw = *mut stc_slot_head

pub type stc_word_deque_value = u64

@[repr(C)]
pub type stc_word_deque { pub cbuf: *mut u64 = null, pub start: i64 = 0, pub end: i64 = 0, pub capmask: i64 = 0 }
impl Copy for stc_word_deque

@[repr(C)]
pub type stc_word_deque_iter { pub ref: *mut u64 = null, pub pos: i64 = 0, pub _s: *const stc_word_deque = null }
impl Copy for stc_word_deque_iter

pub type stc_word_deque_raw = u64

@[repr(C)]
pub type stc_slotref { pub cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> i32] = null, pub ptr: *const c_void = null, pub with_cmp: *const c_void = null, pub with_env: *const c_void = null }
impl Copy for stc_slotref

pub type stc_slotrefs = stc_slotref

pub type stc_slotrefs_value = stc_slotref

pub type stc_slotrefs_raw = stc_slotref

pub type stc_i64s = i64

pub type stc_i64s_value = i64

pub type stc_i64s_raw = i64

pub type stc_u64s = u64

pub type stc_u64s_value = u64

pub type stc_u64s_raw = u64

pub type stc_f64s = f64

pub type stc_f64s_value = f64

pub type stc_f64s_raw = f64

@[repr(C)]
pub type cbits { pub buffer: *mut u64 = null, pub _size: i64 = 0 }
impl Copy for cbits

pub fn i_keydrop[T](p: T) -> i32 {
    0
}
pub let c_declared: i32 = 1
pub let c_no_atomic: i32 = 2
pub let c_use_arc2: i32 = 4
pub let c_use_rc2: i32 = 4
pub let c_no_clone: i32 = 8
pub let c_use_eq: i32 = 16
pub let c_use_cmp: i32 = 32
pub let c_use_compare: i32 = 48
pub let c_compare_key: i32 = 64
pub let c_class_key: i32 = 128
pub let c_class_val: i32 = 256
pub let c_pro_key: i32 = 512
pub let c_pro_val: i32 = 1024
pub fn i_less[T](x: T, y: T) -> i32 {
    (((unsafe *x) < (unsafe *y)) as i32)
}
pub fn i_cmp[T](x: T, y: T) -> T {
    (i_less(y, x) - i_less(x, y))
}
pub fn i_keyfrom[T](v: T) -> T {
    v
}
pub fn i_keytoraw[T](vp: T) -> T {
    (unsafe *vp)
}
pub fn i_keyclone[T](v: T) -> T {
    v
}
pub let i_max_load_factor: f32 = 0.80
pub fn i_eq[T](x: T, y: T) -> i32 {
    (((unsafe *x) == (unsafe *y)) as i32)
}
pub type Self = cbits
@[repr(C)]
pub type fmt_stream { pub data: *mut c_char = null, pub cap: i64 = 0, pub len: i64 = 0, pub overwrite: bool = false }
impl Copy for fmt_stream

pub let fmt_sv = "{:.*s}"
@[repr(C)]
pub type crand64 { pub data: [u64; 4] = [0 as u64; 4] }
impl Copy for crand64

@[repr(C)]
pub type crand64_normal_dist { pub mean: f64 = 0.0, pub stddev: f64 = 0.0, pub _next: f64 = 0.0, pub _has_next: i32 = 0 }
impl Copy for crand64_normal_dist

@[repr(C)]
pub type crand64_uniform_dist { pub low: i64 = 0, pub range: u64 = 0, pub threshold: u64 = 0 }
impl Copy for crand64_uniform_dist

@[repr(C)]
pub type crand32 { pub data: [u32; 4] = [0 as u32; 4] }
impl Copy for crand32

@[repr(C)]
pub type crand32_uniform_dist { pub low: i32 = 0, pub range: u32 = 0, pub threshold: u32 = 0 }
impl Copy for crand32_uniform_dist

pub type crandWS = crand64
pub type cco_position = i32

pub let cco_POS_INIT: i32 = 0
pub let cco_POS_DONE: i32 = -1
pub let cco_POS_FINAL: i32 = -2
pub type cco_status_bits = i32

pub let cco_DONE: i32 = 0
pub let cco_AWAIT: i32 = 1073741824
pub let cco_SUSPEND: i32 = 536870912
pub let cco_YIELD: i32 = 268435456
pub let cco_RECEIVE: i32 = 134217728
@[repr(C)]
pub type cco_group { pub await_count: i32 = 0, pub __bits_0: u32 = 0 }
impl Copy for cco_group
impl cco_group:
    pub fn spawn_count() -> i32: (((self.__bits_0 << 8) as i32) >> 8) as i32
    pub mut fn set_spawn_count(v: i32): self.__bits_0 = (self.__bits_0 & ~((16777215 as u32) << 0)) | (((v as u32) & 16777215) << 0)
    pub fn on_error() -> u32: ((self.__bits_0 >> 24) & 127) as u32
    pub mut fn set_on_error(v: u32): self.__bits_0 = (self.__bits_0 & ~((127 as u32) << 24)) | (((v as u32) & 127) << 24)
    pub fn cancelled() -> u32: ((self.__bits_0 >> 31) & 1) as u32
    pub mut fn set_cancelled(v: u32): self.__bits_0 = (self.__bits_0 & ~((1 as u32) << 31)) | (((v as u32) & 1) << 31)
comptime fn __ci_layout_cco_group() -> Unit:
    if sizeof[*const u8]() == 8 and (sizeof[cco_group]() != 8 or offsetof[cco_group](__bits_0) != 4): comptime_error("cco_group: the bitfield layout this migration recorded (D147) differs on this target")
const __ci_layout_cco_group_check: Unit = __ci_layout_cco_group()

@[repr(C)]
pub type cco_info = union { pub num: i64 = 0, pub str: *const c_char = null, pub ptr: *mut c_void = null }
impl Copy for cco_info

@[repr(C)]
pub type cco_err_t { pub code: i32 = 0, pub line: i32 = 0, pub file: *const c_char = null, pub info: cco_info }
impl Copy for cco_err_t

@[repr(C)]
pub type cco_task_state { pub fib: *mut cco_task_fiber = null, pub parent_grp: *mut cco_group = null, pub tmp_grp: *mut cco_group = null, pub pos: i32 = 0, pub finalizing: bool = false, pub scope_idx: i8 = 0, pub curr_scope: i8 = 0, pub __bits_0: u8 = 0, pub group: [cco_group; 1] }
impl Copy for cco_task_state
impl cco_task_state:
    pub fn n_scopes() -> i8: (((self.__bits_0 << 1) as i8) >> 1) as i8
    pub mut fn set_n_scopes(v: i8): self.__bits_0 = (self.__bits_0 & ~((127 as u8) << 0)) | (((v as u8) & 127) << 0)
    pub fn scoped() -> u8: ((self.__bits_0 >> 7) & 1) as u8
    pub mut fn set_scoped(v: u8): self.__bits_0 = (self.__bits_0 & ~((1 as u8) << 7)) | (((v as u8) & 1) << 7)
comptime fn __ci_layout_cco_task_state() -> Unit:
    if sizeof[*const u8]() == 8 and (sizeof[cco_task_state]() != 40 or offsetof[cco_task_state](__bits_0) != 31): comptime_error("cco_task_state: the bitfield layout this migration recorded (D147) differs on this target")
const __ci_layout_cco_task_state_check: Unit = __ci_layout_cco_task_state()

pub type cco_base_state = cco_task_state

@[repr(C)]
pub type cco_base { pub state: cco_task_state }
impl Copy for cco_base

pub type cco_task_data_ptr_check = [i32; 4]

pub type cco_task_data_ptr = *mut c_void

@[repr(C)]
pub type cco_task_fiber { pub task: *mut cco_task = null, pub data: *mut c_void = null, pub failed_grp: *mut cco_group = null, pub cur_awaiter: *mut cco_task = null, pub next: *mut cco_task_fiber = null, pub parent: *mut cco_task_fiber = null, pub recover_state: cco_task_state, pub error_: cco_err_t, pub cur_awaitbits: i32 = 0, pub status: i32 = 0 }
impl Copy for cco_task_fiber

@[repr(C)]
pub type cco_task_base { pub func: Option[unsafe extern "C" fn(*mut cco_task) -> i32] = null, pub awaiter: *mut cco_task = null, pub awaitbits: i32 = 0, pub state: cco_task_state }
impl Copy for cco_task_base

@[repr(C)]
pub type cco_task { pub base: cco_task_base }
impl Copy for cco_task

pub type cco_fiber = cco_task_fiber

pub type cco_err_policy = i32

pub let cco_POLICY_SHUTDOWN: i32 = 0
pub let cco_POLICY_NOTIFY: i32 = 1
pub let cco_POLICY_IGNORE: i32 = 2
@[repr(C)]
pub type cco_semaphore { pub acq_count: i64 = 0 }
impl Copy for cco_semaphore

@[repr(C)]
pub type cco_timer { pub duration: f64 = 0.0, pub start_time: i64 = 0 }
impl Copy for cco_timer

pub let cco_OK: i32 = 0
pub let cco_CANCEL: u32 = 1073741824
pub let cco_SHUTDOWN: u32 = 536870912
pub let cco_SUBTASK_FAIL: u32 = 536870913
pub let cco_NONE: i32 = 0
pub fn cco_timer_freq() -> i64 {
    1000000i64
}
@[repr(C)]
pub type URange16 { pub lo: u16 = 0, pub hi: u16 = 0 }
impl Copy for URange16

@[repr(C)]
pub type UGroup { pub r16: *const URange16 = null, pub nr16: i32 = 0 }
impl Copy for UGroup

pub let cutf8_dtab: List[u8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 10, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 3, 3, 11, 6, 6, 6, 5, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 12, 24, 36, 60, 96, 84, 12, 12, 12, 48, 72, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0, 12, 12, 12, 12, 12, 0, 12, 0, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 24, 12, 12, 12, 12, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12, 12, 36, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12, 12, 36, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12]
