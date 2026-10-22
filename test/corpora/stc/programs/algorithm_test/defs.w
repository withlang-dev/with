// std.stc_testing.defs — shared definitions for migrated PCRE2
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
pub extern fn strlen(s: *const i8) -> i64
pub extern fn strcmp(a: *const i8, b: *const i8) -> i32
pub extern fn strncmp(a: *const i8, b: *const i8, n: i64) -> i32
pub extern fn strchr(s: *const i8, c: i32) -> *mut i8
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

pub type c_char = i8
pub type c_short = i16
pub type c_ushort = u16
pub type c_int = i32
pub type c_uint = u32
pub type c_long = i64
pub type c_ulong = u64
pub type c_longlong = i64
pub type c_ulonglong = u64
pub type c_longdouble = f64
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

@[repr(C)]
pub type cutf8_decode_t { pub state: c_uint = 0, pub codep: c_uint = 0 }
impl Copy for cutf8_decode_t

pub type csview_value = c_char

@[repr(C)]
pub type csview { pub buf: *mut i8 = null, pub size: c_long = 0 }
impl Copy for csview

@[repr(C)]
pub type csview_iter_u8 { chr: csview, end: *mut i8 = null, dec: cutf8_decode_t }
impl Copy for csview_iter_u8
@[repr(C)]
pub type csview_iter = union { pub u8_: csview_iter_u8, pub chr: csview, pub ref: *mut i8 = null }
impl Copy for csview_iter

pub type zsview_value = c_char

@[repr(C)]
pub type zsview { pub str_: *mut i8 = null, pub size: c_long = 0 }
impl Copy for zsview

@[repr(C)]
pub type zsview_iter_u8 { chr: csview, dec: cutf8_decode_t }
impl Copy for zsview_iter_u8
@[repr(C)]
pub type zsview_iter = union { pub u8_: zsview_iter_u8, pub chr: csview, pub ref: *mut i8 = null }
impl Copy for zsview_iter

pub type cstr_value = c_char

@[repr(C)]
pub type cstr_buf { pub data: *mut i8 = null, pub size: c_long = 0, pub cap: c_long = 0 }
impl Copy for cstr_buf

@[repr(C)]
pub type cstr_sml { data: [c_char; 23] = [0 as c_char; 23], size: u8 = 0 }
impl Copy for cstr_sml
@[repr(C)]
pub type cstr_lon { data: *mut i8 = null, size: c_ulong = 0, ncap: c_ulong = 0 }
impl Copy for cstr_lon
@[repr(C)]
pub type cstr = union { pub sml: cstr_sml, pub lon: cstr_lon }
impl Copy for cstr

@[repr(C)]
pub type cstr_iter_u8 { chr: csview, dec: cutf8_decode_t }
impl Copy for cstr_iter_u8
@[repr(C)]
pub type cstr_iter = union { pub u8_: cstr_iter_u8, pub chr: csview, pub ref: *const i8 = null }
impl Copy for cstr_iter

pub type cstr_raw = *const i8

pub type isize_t = c_long

pub type isize_ = c_long

pub type IVec_value = c_int

@[repr(C)]
pub type IVec_iter { pub ref: *mut c_int = null, pub end: *mut c_int = null }
impl Copy for IVec_iter

@[repr(C)]
pub type IVec { pub data: *mut c_int = null, pub size: c_long = 0, pub capacity: c_long = 0 }
impl Copy for IVec

pub type IVec_raw = c_int

pub type crange_value = c_long

@[repr(C)]
pub type crange { pub start: c_long = 0, pub end: c_long = 0, pub step: c_long = 0, pub value: c_long = 0 }
impl Copy for crange

@[repr(C)]
pub type crange_iter { pub ref: *mut c_long = null, pub end: c_long = 0, pub step: c_long = 0 }
impl Copy for crange_iter

pub type crange32_value = c_int

@[repr(C)]
pub type crange32 { pub start: c_int = 0, pub end: c_int = 0, pub step: c_int = 0, pub value: c_int = 0 }
impl Copy for crange32

@[repr(C)]
pub type crange32_iter { pub ref: *mut c_int = null, pub end: c_int = 0, pub step: c_int = 0 }
impl Copy for crange32_iter

@[repr(C)]
pub type _flt_base { pub sn_top: u8 = 0, pub sb_top: u8 = 0, pub done: bool = false, pub sb: [bool; 20] = [false as bool; 20], pub sn: [c_uint; 20] = [0 as c_uint; 20] }
impl Copy for _flt_base

pub let cutf8_ACCEPT: c_int = 0
pub let cutf8_REJECT: c_int = 12
pub type cutf8_group = c_uint

pub let U8G_Cc: c_int = 0
pub let U8G_L: c_int = 1
pub let U8G_Lm: c_int = 2
pub let U8G_Lt: c_int = 3
pub let U8G_Nd: c_int = 4
pub let U8G_Nl: c_int = 5
pub let U8G_No: c_int = 6
pub let U8G_P: c_int = 7
pub let U8G_Pc: c_int = 8
pub let U8G_Pd: c_int = 9
pub let U8G_Pe: c_int = 10
pub let U8G_Pf: c_int = 11
pub let U8G_Pi: c_int = 12
pub let U8G_Ps: c_int = 13
pub let U8G_Sc: c_int = 14
pub let U8G_Sk: c_int = 15
pub let U8G_Sm: c_int = 16
pub let U8G_Zl: c_int = 17
pub let U8G_Zp: c_int = 18
pub let U8G_Zs: c_int = 19
pub let U8G_Arabic: c_int = 20
pub let U8G_Bengali: c_int = 21
pub let U8G_Cyrillic: c_int = 22
pub let U8G_Devanagari: c_int = 23
pub let U8G_Georgian: c_int = 24
pub let U8G_Greek: c_int = 25
pub let U8G_Han: c_int = 26
pub let U8G_Hiragana: c_int = 27
pub let U8G_Katakana: c_int = 28
pub let U8G_Latin: c_int = 29
pub let U8G_Thai: c_int = 30
pub let U8G_SIZE: c_int = 31
pub let cstr_s_cap: c_int = 22
pub type _istride = c_int

pub type _ituple3 = [c_int; 3]

@[repr(C)]
pub type cspan_tuple1 { pub d: [c_int; 1] = [0 as c_int; 1] }
impl Copy for cspan_tuple1

@[repr(C)]
pub type cspan_tuple2 { pub d: [c_int; 2] = [0 as c_int; 2] }
impl Copy for cspan_tuple2

@[repr(C)]
pub type cspan_tuple3 { pub d: [c_int; 3] = [0 as c_int; 3] }
impl Copy for cspan_tuple3

@[repr(C)]
pub type cspan_tuple4 { pub d: [c_int; 4] = [0 as c_int; 4] }
impl Copy for cspan_tuple4

@[repr(C)]
pub type cspan_tuple5 { pub d: [c_int; 5] = [0 as c_int; 5] }
impl Copy for cspan_tuple5

@[repr(C)]
pub type cspan_tuple6 { pub d: [c_int; 6] = [0 as c_int; 6] }
impl Copy for cspan_tuple6

@[repr(C)]
pub type cspan_tuple7 { pub d: [c_int; 7] = [0 as c_int; 7] }
impl Copy for cspan_tuple7

@[repr(C)]
pub type cspan_tuple8 { pub d: [c_int; 8] = [0 as c_int; 8] }
impl Copy for cspan_tuple8

pub type cspan_layout = c_uint

pub let c_ROWMAJOR: c_int = 0
pub let c_COLMAJOR: c_int = 1
pub let c_STRIDED: c_int = 2
pub type ISpan_value = c_int

pub type ISpan_raw = c_int

@[repr(C)]
pub type ISpan { pub data: *mut c_int = null, pub shape: [c_int; 1] = [0 as c_int; 1], pub stride: cspan_tuple1 }
impl Copy for ISpan

@[repr(C)]
pub type ISpan_iter { pub ref: *mut c_int = null, pub _s: *const ISpan = null, pub pos: [c_int; 1] = [0 as c_int; 1] }
impl Copy for ISpan_iter

// out/tmp/action-scratch/stc-migrate-tests/source-algorithm_test/algorithm_test.c:9:1: demoted to opaque
pub type stc_nostruct = opaque

pub type ctest_nullary_run_func = extern "C" fn() -> Unit

pub type ctest_unary_run_func = unsafe extern "C" fn(*mut c_void) -> Unit

pub type ctest_setup_func = unsafe extern "C" fn(*mut c_void) -> Unit

pub type ctest_teardown_func = unsafe extern "C" fn(*mut c_void) -> Unit

@[repr(C)]
pub type ctest_run_func_union = union { pub nullary: Option[extern "C" fn() -> Unit] = null, pub unary: Option[unsafe extern "C" fn(*mut c_void) -> Unit] = null }
impl Copy for ctest_run_func_union

@[repr(C)]
pub type ctest { pub magic0: c_uint = 0, pub padding: c_uint = 0, pub ssname: *const i8 = null, pub ttname: *const i8 = null, pub run: ctest_run_func_union, pub data: *mut c_void = null, pub setup: *mut Option[extern "C" fn(*mut c_void) -> Unit] = null, pub teardown: *mut Option[extern "C" fn(*mut c_void) -> Unit] = null, pub skip: c_int = 0, pub magic1: c_uint = 0 }
impl Copy for ctest

pub type Action_tag = c_uint

pub let ActionSpeak: c_int = 105000
pub let ActionLog: c_int = 105001
pub let ActionQuit: c_int = 105002
pub let ActionRunFunc: c_int = 105003
pub type ActionSpeak_type = cstr

pub type ActionSpeak_sumtype = Action

pub type ActionLog_type = cstr

pub type ActionLog_sumtype = Action

pub type ActionQuit_type = bool

pub type ActionQuit_sumtype = Action

@[repr(C)]
pub type ActionRunFunc_type { pub func: Option[extern "C" fn(c_int, c_int) -> c_int] = null, pub v1: c_int = 0, pub v2: c_int = 0 }
impl Copy for ActionRunFunc_type

pub type ActionRunFunc_sumtype = Action

@[repr(C)]
pub type Action_ActionSpeak { id: i32 = 0, item: cstr }
impl Copy for Action_ActionSpeak
@[repr(C)]
pub type Action_ActionLog { id: i32 = 0, item: cstr }
impl Copy for Action_ActionLog
@[repr(C)]
pub type Action_ActionQuit { id: i32 = 0, item: bool = false }
impl Copy for Action_ActionQuit
@[repr(C)]
pub type Action_ActionRunFunc { id: i32 = 0, item: ActionRunFunc_type }
impl Copy for Action_ActionRunFunc
@[repr(C)]
pub type Action = union { pub tag_id: c_int = 0, pub tag: i32 = 0, pub ActionSpeak: Action_ActionSpeak, pub ActionLog: Action_ActionLog, pub ActionQuit: Action_ActionQuit, pub ActionRunFunc: Action_ActionRunFunc }
impl Copy for Action

pub let c_svfmt = "%.*s"
pub fn cstr_raw_cmp[T](x: T, y: T) -> c_int {
    strcmp((unsafe *x), (unsafe *y))
}
pub fn cstr_raw_eq[T](x: T, y: T) -> c_int {
    ((cstr_raw_cmp(x, y) == 0) as c_int)
}
pub fn cstr_raw_hash[T](vp: T) -> T {
    unsafe { c_hash_str((unsafe *vp)) }
}
pub let ISIZE_MIN: c_long = (0 - 9223372036854775807 - 1)
pub let ISIZE_MAX: c_long = 9223372036854775807
pub let c_ZI: [c_char; 3] = [108, 105, 0]
pub let c_ZU: [c_char; 3] = [108, 117, 0]
pub let c_NPOS: c_long = 9223372036854775807
pub fn c_literal[T](p_T: T) -> T {
    p_T
}
pub fn c_countof[T](a: T) -> c_long {
    (sizeof[T]() as c_long)
}
pub fn c_strlen[T](s: T) -> c_long {
    (strlen(s) as c_long)
}
pub fn c_u2i_cast[T](u: T) -> c_long {
    ((if 1 != 0: u else: (1 as usize)) as c_long)
}
pub fn c_i2u_cast[T](i: T) -> usize {
    ((if 1 != 0: i else: -1) as usize)
}
pub fn c_uless[T](a: T, b: T) -> c_int {
    (((a as usize) < (b as usize)) as c_int)
}
pub fn c_default_eq[T](x: T, y: T) -> c_int {
    (((unsafe *x) == (unsafe *y)) as c_int)
}
pub fn c_default_less[T](x: T, y: T) -> c_int {
    (((unsafe *x) < (unsafe *y)) as c_int)
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
pub fn c_arraylen[T](a: T) -> c_long {
    c_countof(a)
}
pub let FNV_BASIS: c_ulonglong = 0xcbf29ce484222325
pub let FNV_PRIME: c_longlong = 0x00000100000001b3
pub let c_declared: c_int = 1
pub let c_no_atomic: c_int = 2
pub let c_use_arc2: c_int = 4
pub let c_use_rc2: c_int = 4
pub let c_no_clone: c_int = 8
pub let c_use_eq: c_int = 16
pub let c_use_cmp: c_int = 32
pub let c_use_compare: c_int = 48
pub let c_compare_key: c_int = 64
pub let c_class_key: c_int = 128
pub let c_class_val: c_int = 256
pub let c_pro_key: c_int = 512
pub let c_pro_val: c_int = 1024
pub fn i_eq[T](x: T, y: T) -> c_int {
    (((unsafe *x) == (unsafe *y)) as c_int)
}
pub fn i_less[T](x: T, y: T) -> c_int {
    (((unsafe *x) < (unsafe *y)) as c_int)
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
pub fn i_keydrop[T](vp: T) -> T {
    vp
}
pub fn crange_make_1[T](stop: T) -> crange {
    crange_make_3(0, stop, 1)
}
pub fn crange_make_2[T](start: T, stop: T) -> crange {
    crange_make_3(start, stop, 1)
}
pub fn crange32_make_1[T](stop: T) -> crange32 {
    crange32_make_3(0, stop, 1)
}
pub fn crange32_make_2[T](start: T, stop: T) -> crange32 {
    crange32_make_3(start, stop, 1)
}
pub fn c_fflt_take[T](i: T, n: T) -> T {
    unsafe { _flt_take(&i.base, n) }
}
pub fn c_fflt_takewhile[T](i: T, pred: T) -> T {
    unsafe { _flt_takewhile(&i.base, pred) }
}
pub fn c_fflt_getcount[T](i: T) -> T {
    i.base.sn[i.base.sn_top]
}
pub fn c_fflt_src[T](i: T) -> T {
    i.iter.ref
}
pub let c_NFILTERS: c_int = 20
pub let c_END: c_int = 2147483647
pub let CTEST_FLT_EPSILON: f64 = 1e-5
pub let CTEST_DBL_EPSILON: f64 = 1e-12
pub fn f_is_even[T](v: T) -> c_int {
    (((v & 1) == 0) as c_int)
}
pub fn f_is_odd[T](v: T) -> c_int {
    (((v & 1) == 1) as c_int)
}
@[repr(C)]
pub type CaseMapping { pub c1: c_ushort = 0, pub c2: c_ushort = 0, pub m2: c_ushort = 0 }
impl Copy for CaseMapping

pub let casefold_len: c_int = 192
@[repr(C)]
pub type fn_tocase_anon { pub conv_asc: Option[extern "C" fn(c_int) -> c_int] = null, pub conv_utf: Option[extern "C" fn(c_uint) -> c_uint] = null }
impl Copy for fn_tocase_anon

@[repr(C)]
pub type fmt_stream { pub data: *mut i8 = null, pub cap: c_long = 0, pub len: c_long = 0, pub overwrite: bool = false }
impl Copy for fmt_stream

pub let fmt_sv = "{:.*s}"
@[repr(C)]
pub type crand64 { pub data: [c_ulonglong; 4] = [0 as c_ulonglong; 4] }
impl Copy for crand64

@[repr(C)]
pub type crand64_normal_dist { pub mean: f64 = 0.0, pub stddev: f64 = 0.0, pub _next: f64 = 0.0, pub _has_next: c_int = 0 }
impl Copy for crand64_normal_dist

@[repr(C)]
pub type crand64_uniform_dist { pub low: c_longlong = 0, pub range: c_ulonglong = 0, pub threshold: c_ulonglong = 0 }
impl Copy for crand64_uniform_dist

@[repr(C)]
pub type crand32 { pub data: [c_uint; 4] = [0 as c_uint; 4] }
impl Copy for crand32

@[repr(C)]
pub type crand32_uniform_dist { pub low: c_int = 0, pub range: c_uint = 0, pub threshold: c_uint = 0 }
impl Copy for crand32_uniform_dist

pub type crandWS = crand64
@[repr(C)]
pub type URange16 { pub lo: c_ushort = 0, pub hi: c_ushort = 0 }
impl Copy for URange16

@[repr(C)]
pub type UGroup { pub r16: *const URange16 = null, pub nr16: c_int = 0 }
impl Copy for UGroup

pub let cutf8_dtab: List[u8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 10, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 3, 3, 11, 6, 6, 6, 5, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 12, 24, 36, 60, 96, 84, 12, 12, 12, 48, 72, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0, 12, 12, 12, 12, 12, 0, 12, 0, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 24, 12, 12, 12, 12, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12, 12, 36, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12, 12, 36, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12]
