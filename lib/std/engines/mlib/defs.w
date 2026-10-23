// std.engines.mlib.defs — shared definitions for migrated PCRE2
use std.option
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
pub extern fn strlen(s: *const i8) -> u64
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
pub type m_core_backoff_s { pub count: c_uint = 0, pub seed: c_uint = 0 }
impl Copy for m_core_backoff_s

pub type m_core_backoff_ct = [m_core_backoff_s; 1]

// out/tmp/mlib-boot/source/m-core.h:5610:8: demoted to opaque
pub type m_string_s = opaque

pub type m_serial_return_code_e = c_int

pub let M_SERIAL_OK_DONE: c_int = 0
pub let M_SERIAL_OK_CONTINUE: c_int = 1
pub let M_SERIAL_FAIL: c_int = 2
pub let M_SERIAL_FAIL_RETRY: c_int = 4
pub type m_serial_return_code_t = i32

@[repr(C)]
pub type m_serial_ll_u = union { pub b: bool = false, pub c: c_char = 0, pub i: c_int = 0, pub l: c_long = 0, pub ll: c_longlong = 0, pub f: f32 = 0.0, pub d: f64 = 0.0, pub e: c_longdouble = 0.0, pub s: c_ulong = 0, pub u: c_ulong = 0, pub p: *mut c_void = null, pub cstr: *const i8 = null, pub r: i32 = 0 }
impl Copy for m_serial_ll_u

pub type m_serial_ll_ct = m_serial_ll_u

@[repr(C)]
pub type m_serial_local_s { pub data: [m_serial_ll_u; 4] }
impl Copy for m_serial_local_s

pub type m_serial_local_t = [m_serial_local_s; 1]

@[repr(C)]
pub type m_serial_read_s { pub m_interface: *const m_serial_read_interface_s = null, pub tmp: m_serial_ll_u, pub data: [m_serial_ll_u; 4] }
impl Copy for m_serial_read_s

pub type m_serial_read_t = [m_serial_read_s; 1]

@[repr(C)]
pub type m_serial_read_interface_s { pub read_boolean: Option[unsafe extern "C" fn(*mut m_serial_read_s, *mut bool) -> i32] = null, pub read_integer: Option[unsafe extern "C" fn(*mut m_serial_read_s, *mut c_longlong, c_ulong) -> i32] = null, pub read_float: Option[unsafe extern "C" fn(*mut m_serial_read_s, *mut c_longdouble, c_ulong) -> i32] = null, pub read_string: Option[unsafe extern "C" fn(*mut m_serial_read_s, *mut m_string_s) -> i32] = null, pub read_array_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s, *mut c_ulong) -> i32] = null, pub read_array_next: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s) -> i32] = null, pub read_map_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s, *mut c_ulong) -> i32] = null, pub read_map_value: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s) -> i32] = null, pub read_map_next: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s) -> i32] = null, pub read_tuple_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s) -> i32] = null, pub read_tuple_id: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s, **const i8, c_int, *mut c_int) -> i32] = null, pub read_variant_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s, **const i8, c_int, *mut c_int) -> i32] = null, pub read_variant_end: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_read_s) -> i32] = null }
impl Copy for m_serial_read_interface_s

pub type m_serial_read_interface_t = m_serial_read_interface_s

@[repr(C)]
pub type m_serial_write_s { pub m_interface: *const m_serial_write_interface_s = null, pub tmp: m_serial_ll_u, pub data: [m_serial_ll_u; 4] }
impl Copy for m_serial_write_s

pub type m_serial_write_t = [m_serial_write_s; 1]

@[repr(C)]
pub type m_serial_write_interface_s { pub write_boolean: Option[unsafe extern "C" fn(*mut m_serial_write_s, bool) -> i32] = null, pub write_integer: Option[unsafe extern "C" fn(*mut m_serial_write_s, c_longlong, c_ulong) -> i32] = null, pub write_float: Option[unsafe extern "C" fn(*mut m_serial_write_s, c_longdouble, c_ulong) -> i32] = null, pub write_string: Option[unsafe extern "C" fn(*mut m_serial_write_s, *c_char, c_ulong) -> i32] = null, pub write_array_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s, c_ulong) -> i32] = null, pub write_array_next: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null, pub write_array_end: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null, pub write_map_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s, c_ulong) -> i32] = null, pub write_map_value: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null, pub write_map_next: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null, pub write_map_end: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null, pub write_tuple_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null, pub write_tuple_id: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s, **const i8, c_int, c_int) -> i32] = null, pub write_tuple_end: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null, pub write_variant_start: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s, **const i8, c_int, c_int) -> i32] = null, pub write_variant_end: Option[unsafe extern "C" fn(*mut m_serial_local_s, *mut m_serial_write_s) -> i32] = null }
impl Copy for m_serial_write_interface_s

pub type m_serial_write_interface_t = m_serial_write_interface_s

pub type m_bptr33_transaction_kind_t = c_int

pub let M_BPTR33_NONE: c_int = 0
pub let M_BPTR33_NEW_NODE: c_int = 1
pub let M_BPTR33_INIT_KEY: c_int = 2
pub let M_BPTR33_MOVE_KEY: c_int = 3
pub let M_BPTR33_INIT_VALUE: c_int = 4
pub let M_BPTR33_SPLIT_LEAF: c_int = 5
pub let M_BPTR33_SPLIT_NODE: c_int = 6
pub let M_BPTR33_SHIFT_LEAF: c_int = 7
pub let M_BPTR33_SHIFT_NODE: c_int = 8
pub let M_BPTR33_INC_SIZE: c_int = 9
@[repr(C)]
pub type m_bptr33_transaction_record_t { pub type_: i32 = 0, pub data_dst: *mut c_void = null, pub data_src: *mut c_void = null }
impl Copy for m_bptr33_transaction_record_t

@[repr(C)]
pub type m_bptr33_transaction_t_anon { pub size: c_int = 0, pub tab: [m_bptr33_transaction_record_t; 265] }
impl Copy for m_bptr33_transaction_t_anon

pub type m_bptr33_transaction_t = [m_bptr33_transaction_t_anon; 1]

@[repr(C)]
pub type mlib_slot_head { pub cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> c_int] = null, pub clone: Option[unsafe extern "C" fn(*const c_void) -> *mut c_void] = null, pub drop: Option[unsafe extern "C" fn(*mut c_void) -> Unit] = null, pub entry: *mut c_void = null }
impl Copy for mlib_slot_head

pub type mlib_slot = *mut mlib_slot_head

pub type mlib_slot_tree_itref_ct = *mut mlib_slot_head

@[repr(C)]
pub type mlib_slot_tree_kind_s = union { pub node: [*mut mlib_slot_tree_node_s; 18] = [null as *mut mlib_slot_tree_node_s; 18] }
impl Copy for mlib_slot_tree_kind_s

@[repr(C)]
pub type mlib_slot_tree_node_s { pub num: c_int = 0, pub key: [*mut mlib_slot_head; 17] = [null as *mut mlib_slot_head; 17], pub next: *mut mlib_slot_tree_node_s = null, pub prev: *mut mlib_slot_tree_node_s = null, pub kind: mlib_slot_tree_kind_s }
impl Copy for mlib_slot_tree_node_s

pub type mlib_slot_tree_node_ct = *mut mlib_slot_tree_node_s

@[repr(C)]
pub type mlib_slot_tree_s { pub root: *mut mlib_slot_tree_node_s = null, pub size: c_ulong = 0 }
impl Copy for mlib_slot_tree_s

pub type mlib_slot_tree_t = [mlib_slot_tree_s; 1]

pub type mlib_slot_tree_ptr = *mut mlib_slot_tree_s

pub type mlib_slot_tree_srcptr = *const mlib_slot_tree_s

pub type mlib_slot_tree_subtype_ct = *mut mlib_slot_head

pub type mlib_slot_tree_key_ct = *mut mlib_slot_head

pub type mlib_slot_tree_value_ct = *mut mlib_slot_head

pub type mlib_slot_tree_ct = [mlib_slot_tree_s; 1]

@[repr(C)]
pub type mlib_slot_tree_parent_it_s { pub num: c_int = 0, pub parent: [*mut mlib_slot_tree_node_s; 65] = [null as *mut mlib_slot_tree_node_s; 65] }
impl Copy for mlib_slot_tree_parent_it_s

pub type mlib_slot_tree_pit_ct = [mlib_slot_tree_parent_it_s; 1]

@[repr(C)]
pub type mlib_slot_tree_it_s { pub node: *mut mlib_slot_tree_node_s = null, pub idx: c_int = 0 }
impl Copy for mlib_slot_tree_it_s

pub type mlib_slot_tree_it_t = [mlib_slot_tree_it_s; 1]

pub type mlib_slot_tree_it_ct = [mlib_slot_tree_it_s; 1]

pub let M_USE_STDARG: c_int = 1
pub let M_USE_SMALL_NAME: c_int = 1
pub let M_CORE_VERSION_MAJOR: c_int = 0
pub let M_CORE_VERSION_MINOR: c_int = 8
pub let M_CORE_VERSION_PATCHLEVEL: c_int = 2
pub fn M_LIKELY[T](cond: T) -> T {
    (if (if cond != 0: 0 else: 1) != 0: 0 else: 1)
}
pub fn M_UNLIKELY[T](cond: T) -> T {
    (if (if cond != 0: 0 else: 1) != 0: 0 else: 1)
}
pub let M_ALIGN_FOR_CACHELINE_EXCLUSION: c_int = 64
pub fn M_MEMORY_DEL[T](ctx: T, ptr: T) {
    with_free((ptr) as *mut u8)
}
pub fn M_MEMORY_FREE[T](ctx: T, type_: T, ptr: T, o: T) {
    with_free((ptr) as *mut u8)
}
pub let M_USE_GLOBAL_CONTEXT: c_int = 0
pub fn M_UNUSED_CONTEXT() {
    return
}
pub fn M_GLOBAL_CONTEXT() {
    return
}
pub fn M_ASSERT_SLOW[T](n: T) -> T {
    (0 as Unit)
}
pub fn M_UNLIKELY_NOMEM[T](cond: T) -> T {
    M_UNLIKELY(cond)
}
pub let M_MAX_NB_ARGUMENT: c_int = 52
pub let M_INVI_0: c_int = 1
pub let M_INVI_1: c_int = 0
pub let M_ANDI_00: c_int = 0
pub let M_ANDI_01: c_int = 0
pub let M_ANDI_10: c_int = 0
pub let M_ANDI_11: c_int = 1
pub let M_ANDI_000: c_int = 0
pub let M_ANDI_001: c_int = 0
pub let M_ANDI_010: c_int = 0
pub let M_ANDI_011: c_int = 0
pub let M_ANDI_100: c_int = 0
pub let M_ANDI_101: c_int = 0
pub let M_ANDI_110: c_int = 0
pub let M_ANDI_111: c_int = 1
pub let M_ORI_00: c_int = 0
pub let M_ORI_01: c_int = 1
pub let M_ORI_10: c_int = 1
pub let M_ORI_11: c_int = 1
pub let M_ORI_000: c_int = 0
pub let M_ORI_001: c_int = 1
pub let M_ORI_010: c_int = 1
pub let M_ORI_011: c_int = 1
pub let M_ORI_100: c_int = 1
pub let M_ORI_101: c_int = 1
pub let M_ORI_110: c_int = 1
pub let M_ORI_111: c_int = 1
pub let M_INC_0: c_int = 1
pub let M_INC_1: c_int = 2
pub let M_INC_2: c_int = 3
pub let M_INC_3: c_int = 4
pub let M_INC_4: c_int = 5
pub let M_INC_5: c_int = 6
pub let M_INC_6: c_int = 7
pub let M_INC_7: c_int = 8
pub let M_INC_8: c_int = 9
pub let M_INC_9: c_int = 10
pub let M_INC_10: c_int = 11
pub let M_INC_11: c_int = 12
pub let M_INC_12: c_int = 13
pub let M_INC_13: c_int = 14
pub let M_INC_14: c_int = 15
pub let M_INC_15: c_int = 16
pub let M_INC_17: c_int = 18
pub let M_INC_18: c_int = 19
pub let M_INC_19: c_int = 20
pub let M_INC_20: c_int = 21
pub let M_INC_21: c_int = 22
pub let M_INC_22: c_int = 23
pub let M_INC_23: c_int = 24
pub let M_INC_24: c_int = 25
pub let M_INC_25: c_int = 26
pub let M_INC_26: c_int = 27
pub let M_INC_27: c_int = 28
pub let M_INC_28: c_int = 29
pub let M_INC_29: c_int = 30
pub let M_INC_30: c_int = 31
pub let M_INC_31: c_int = 32
pub let M_INC_33: c_int = 34
pub let M_INC_34: c_int = 35
pub let M_INC_35: c_int = 36
pub let M_INC_36: c_int = 37
pub let M_INC_37: c_int = 38
pub let M_INC_38: c_int = 39
pub let M_INC_39: c_int = 40
pub let M_INC_40: c_int = 41
pub let M_INC_41: c_int = 42
pub let M_INC_42: c_int = 43
pub let M_INC_43: c_int = 44
pub let M_INC_44: c_int = 45
pub let M_INC_45: c_int = 46
pub let M_INC_46: c_int = 47
pub let M_INC_47: c_int = 48
pub let M_INC_48: c_int = 49
pub let M_INC_49: c_int = 50
pub let M_INC_50: c_int = 51
pub let M_INC_51: c_int = 52
pub let M_INC_52: c_int = 53
pub let M_DEC_1: c_int = 0
pub let M_DEC_2: c_int = 1
pub let M_DEC_3: c_int = 2
pub let M_DEC_4: c_int = 3
pub let M_DEC_5: c_int = 4
pub let M_DEC_6: c_int = 5
pub let M_DEC_7: c_int = 6
pub let M_DEC_8: c_int = 7
pub let M_DEC_9: c_int = 8
pub let M_DEC_10: c_int = 9
pub let M_DEC_11: c_int = 10
pub let M_DEC_12: c_int = 11
pub let M_DEC_13: c_int = 12
pub let M_DEC_14: c_int = 13
pub let M_DEC_15: c_int = 14
pub let M_DEC_17: c_int = 16
pub let M_DEC_18: c_int = 17
pub let M_DEC_19: c_int = 18
pub let M_DEC_20: c_int = 19
pub let M_DEC_21: c_int = 20
pub let M_DEC_22: c_int = 21
pub let M_DEC_23: c_int = 22
pub let M_DEC_24: c_int = 23
pub let M_DEC_25: c_int = 24
pub let M_DEC_26: c_int = 25
pub let M_DEC_27: c_int = 26
pub let M_DEC_28: c_int = 27
pub let M_DEC_29: c_int = 28
pub let M_DEC_30: c_int = 29
pub let M_DEC_31: c_int = 30
pub let M_DEC_33: c_int = 32
pub let M_DEC_34: c_int = 33
pub let M_DEC_35: c_int = 34
pub let M_DEC_36: c_int = 35
pub let M_DEC_37: c_int = 36
pub let M_DEC_38: c_int = 37
pub let M_DEC_39: c_int = 38
pub let M_DEC_40: c_int = 39
pub let M_DEC_41: c_int = 40
pub let M_DEC_42: c_int = 41
pub let M_DEC_43: c_int = 42
pub let M_DEC_44: c_int = 43
pub let M_DEC_45: c_int = 44
pub let M_DEC_46: c_int = 45
pub let M_DEC_47: c_int = 46
pub let M_DEC_48: c_int = 47
pub let M_DEC_49: c_int = 48
pub let M_DEC_50: c_int = 49
pub let M_DEC_51: c_int = 50
pub let M_DEC_52: c_int = 51
pub fn M_ADDI_0[T](n: T) -> T {
    n
}
pub fn M_SUBI_0[T](n: T) -> T {
    n
}
pub let M_NOTEQUAL_0_0: c_int = 0
pub let M_NOTEQUAL_1_1: c_int = 0
pub let M_NOTEQUAL_2_2: c_int = 0
pub let M_NOTEQUAL_3_3: c_int = 0
pub let M_NOTEQUAL_4_4: c_int = 0
pub let M_NOTEQUAL_5_5: c_int = 0
pub let M_NOTEQUAL_6_6: c_int = 0
pub let M_NOTEQUAL_7_7: c_int = 0
pub let M_NOTEQUAL_8_8: c_int = 0
pub let M_NOTEQUAL_9_9: c_int = 0
pub let M_NOTEQUAL_10_10: c_int = 0
pub let M_NOTEQUAL_11_11: c_int = 0
pub let M_NOTEQUAL_12_12: c_int = 0
pub let M_NOTEQUAL_13_13: c_int = 0
pub let M_NOTEQUAL_14_14: c_int = 0
pub let M_NOTEQUAL_15_15: c_int = 0
pub let M_NOTEQUAL_17_17: c_int = 0
pub let M_NOTEQUAL_18_18: c_int = 0
pub let M_NOTEQUAL_19_19: c_int = 0
pub let M_NOTEQUAL_20_20: c_int = 0
pub let M_NOTEQUAL_21_21: c_int = 0
pub let M_NOTEQUAL_22_22: c_int = 0
pub let M_NOTEQUAL_23_23: c_int = 0
pub let M_NOTEQUAL_24_24: c_int = 0
pub let M_NOTEQUAL_25_25: c_int = 0
pub let M_NOTEQUAL_26_26: c_int = 0
pub let M_NOTEQUAL_27_27: c_int = 0
pub let M_NOTEQUAL_28_28: c_int = 0
pub let M_NOTEQUAL_29_29: c_int = 0
pub let M_NOTEQUAL_30_30: c_int = 0
pub let M_NOTEQUAL_31_31: c_int = 0
pub let M_NOTEQUAL_33_33: c_int = 0
pub let M_NOTEQUAL_34_34: c_int = 0
pub let M_NOTEQUAL_35_35: c_int = 0
pub let M_NOTEQUAL_36_36: c_int = 0
pub let M_NOTEQUAL_37_37: c_int = 0
pub let M_NOTEQUAL_38_38: c_int = 0
pub let M_NOTEQUAL_39_39: c_int = 0
pub let M_NOTEQUAL_40_40: c_int = 0
pub let M_NOTEQUAL_41_41: c_int = 0
pub let M_NOTEQUAL_42_42: c_int = 0
pub let M_NOTEQUAL_43_43: c_int = 0
pub let M_NOTEQUAL_44_44: c_int = 0
pub let M_NOTEQUAL_45_45: c_int = 0
pub let M_NOTEQUAL_46_46: c_int = 0
pub let M_NOTEQUAL_47_47: c_int = 0
pub let M_NOTEQUAL_48_48: c_int = 0
pub let M_NOTEQUAL_49_49: c_int = 0
pub let M_NOTEQUAL_50_50: c_int = 0
pub let M_NOTEQUAL_51_51: c_int = 0
pub let M_NOTEQUAL_52_52: c_int = 0
pub fn M_PAIR_1[T](a: T, b: T) -> T {
    a
}
pub fn M_PAIR_2[T](a: T, b: T) -> T {
    b
}
pub fn M_TRIPLE_1[T](a: T, b: T, c: T) -> T {
    a
}
pub fn M_TRIPLE_2[T](a: T, b: T, c: T) -> T {
    b
}
pub fn M_TRIPLE_3[T](a: T, b: T, c: T) -> T {
    c
}
pub fn M_QUAD_1[T](a: T, b: T, c: T, d: T) -> T {
    a
}
pub fn M_QUAD_2[T](a: T, b: T, c: T, d: T) -> T {
    b
}
pub fn M_QUAD_3[T](a: T, b: T, c: T, d: T) -> T {
    c
}
pub fn M_QUAD_4[T](a: T, b: T, c: T, d: T) -> T {
    d
}
pub fn M_REVERSE_1[T](_1: T) -> T {
    _1
}
pub fn M_CI_EMPTY_B[T](a: T, b: T) -> T {
    a
}
pub fn M_DELAY0() {
    return
}
pub fn M_MAP_1[T](f: T, _1: T) -> T {
    f(_1)
}
pub fn M_MAP2I_1[T](f: T, d: T, _1: T) -> T {
    f(d, _1)
}
pub fn M_MAP2B_1[T](f: T, d: T, _1: T) -> T {
    f(d, _1)
}
pub fn M_MAP3I_1[T](f: T, d: T, _1: T) -> T {
    f(d, 1, _1)
}
pub fn M_REDUCEI1_1[T](f: T, g: T, _1: T) -> T {
    f(_1)
}
pub fn M_REDUCEI1_2[T](f: T, g: T, _1: T, _2: T) -> T {
    g(f(_1), f(_2))
}
pub fn M_REDUCEI1_3[T](f: T, g: T, _1: T, _2: T, _3: T) -> T {
    g(f(_1), g(f(_2), f(_3)))
}
pub fn M_REDUCEI1_4[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), f(_4))))
}
pub fn M_REDUCEI1_5[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), f(_5)))))
}
pub fn M_REDUCEI1_6[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), f(_6))))))
}
pub fn M_REDUCEI1_7[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), f(_7)))))))
}
pub fn M_REDUCEI1_8[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), f(_8))))))))
}
pub fn M_REDUCEI1_9[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), f(_9)))))))))
}
pub fn M_REDUCEI1_10[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), f(_10))))))))))
}
pub fn M_REDUCEI1_11[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), f(_11)))))))))))
}
pub fn M_REDUCEI1_12[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), f(_12))))))))))))
}
pub fn M_REDUCEI1_13[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), f(_13)))))))))))))
}
pub fn M_REDUCEI1_14[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), f(_14))))))))))))))
}
pub fn M_REDUCEI1_15[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), f(_15)))))))))))))))
}
pub fn M_REDUCEI1_17[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), f(_17)))))))))))))))))
}
pub fn M_REDUCEI1_18[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), f(_18))))))))))))))))))
}
pub fn M_REDUCEI1_19[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), f(_19)))))))))))))))))))
}
pub fn M_REDUCEI1_20[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), f(_20))))))))))))))))))))
}
pub fn M_REDUCEI1_21[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), f(_21)))))))))))))))))))))
}
pub fn M_REDUCEI1_22[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), f(_22))))))))))))))))))))))
}
pub fn M_REDUCEI1_23[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), f(_23)))))))))))))))))))))))
}
pub fn M_REDUCEI1_24[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), f(_24))))))))))))))))))))))))
}
pub fn M_REDUCEI1_25[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), f(_25)))))))))))))))))))))))))
}
pub fn M_REDUCEI1_26[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), f(_26))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_27[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), f(_27)))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_28[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), f(_28))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_29[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), f(_29)))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_30[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), f(_30))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_31[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), f(_31)))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_33[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), f(_33)))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_34[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), f(_34))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_35[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), f(_35)))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_36[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), f(_36))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_37[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), f(_37)))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_38[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), f(_38))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_39[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), f(_39)))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_40[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), f(_40))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_41[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), f(_41)))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_42[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), f(_42))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_43[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), f(_43)))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_44[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), f(_44))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_45[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), f(_45)))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_46[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), g(f(_45), f(_46))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_47[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), g(f(_45), g(f(_46), f(_47)))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_48[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), g(f(_45), g(f(_46), g(f(_47), f(_48))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_49[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), g(f(_45), g(f(_46), g(f(_47), g(f(_48), f(_49)))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_50[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), g(f(_45), g(f(_46), g(f(_47), g(f(_48), g(f(_49), f(_50))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_51[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), g(f(_45), g(f(_46), g(f(_47), g(f(_48), g(f(_49), g(f(_50), f(_51)))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI1_52[T](f: T, g: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T, _52: T) -> T {
    g(f(_1), g(f(_2), g(f(_3), g(f(_4), g(f(_5), g(f(_6), g(f(_7), g(f(_8), g(f(_9), g(f(_10), g(f(_11), g(f(_12), g(f(_13), g(f(_14), g(f(_15), g(f(_16), g(f(_17), g(f(_18), g(f(_19), g(f(_20), g(f(_21), g(f(_22), g(f(_23), g(f(_24), g(f(_25), g(f(_26), g(f(_27), g(f(_28), g(f(_29), g(f(_30), g(f(_31), g(f(_32), g(f(_33), g(f(_34), g(f(_35), g(f(_36), g(f(_37), g(f(_38), g(f(_39), g(f(_40), g(f(_41), g(f(_42), g(f(_43), g(f(_44), g(f(_45), g(f(_46), g(f(_47), g(f(_48), g(f(_49), g(f(_50), g(f(_51), f(_52))))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_1[T](f: T, g: T, d: T, _1: T) -> T {
    f(d, _1)
}
pub fn M_REDUCEI2_2[T](f: T, g: T, d: T, _1: T, _2: T) -> T {
    g(f(d, _1), f(d, _2))
}
pub fn M_REDUCEI2_3[T](f: T, g: T, d: T, _1: T, _2: T, _3: T) -> T {
    g(f(d, _1), g(f(d, _2), f(d, _3)))
}
pub fn M_REDUCEI2_4[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), f(d, _4))))
}
pub fn M_REDUCEI2_5[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), f(d, _5)))))
}
pub fn M_REDUCEI2_6[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), f(d, _6))))))
}
pub fn M_REDUCEI2_7[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), f(d, _7)))))))
}
pub fn M_REDUCEI2_8[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), f(d, _8))))))))
}
pub fn M_REDUCEI2_9[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), f(d, _9)))))))))
}
pub fn M_REDUCEI2_10[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), f(d, _10))))))))))
}
pub fn M_REDUCEI2_11[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), f(d, _11)))))))))))
}
pub fn M_REDUCEI2_12[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), f(d, _12))))))))))))
}
pub fn M_REDUCEI2_13[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), f(d, _13)))))))))))))
}
pub fn M_REDUCEI2_14[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), f(d, _14))))))))))))))
}
pub fn M_REDUCEI2_15[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), f(d, _15)))))))))))))))
}
pub fn M_REDUCEI2_17[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), f(d, _17)))))))))))))))))
}
pub fn M_REDUCEI2_18[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), f(d, _18))))))))))))))))))
}
pub fn M_REDUCEI2_19[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), f(d, _19)))))))))))))))))))
}
pub fn M_REDUCEI2_20[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), f(d, _20))))))))))))))))))))
}
pub fn M_REDUCEI2_21[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), f(d, _21)))))))))))))))))))))
}
pub fn M_REDUCEI2_22[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), f(d, _22))))))))))))))))))))))
}
pub fn M_REDUCEI2_23[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), f(d, _23)))))))))))))))))))))))
}
pub fn M_REDUCEI2_24[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), f(d, _24))))))))))))))))))))))))
}
pub fn M_REDUCEI2_25[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), f(d, _25)))))))))))))))))))))))))
}
pub fn M_REDUCEI2_26[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), f(d, _26))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_27[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), f(d, _27)))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_28[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), f(d, _28))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_29[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), f(d, _29)))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_30[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), f(d, _30))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_31[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), f(d, _31)))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_33[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), f(d, _33)))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_34[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), f(d, _34))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_35[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), f(d, _35)))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_36[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), f(d, _36))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_37[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), f(d, _37)))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_38[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), f(d, _38))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_39[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), f(d, _39)))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_40[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), f(d, _40))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_41[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), f(d, _41)))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_42[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), f(d, _42))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_43[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), f(d, _43)))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_44[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), f(d, _44))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_45[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), f(d, _45)))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_46[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), f(d, _46))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_47[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), f(d, _47)))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_48[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), f(d, _48))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_49[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), f(d, _49)))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_50[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), g(f(d, _49), f(d, _50))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_51[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), g(f(d, _49), g(f(d, _50), f(d, _51)))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2_52[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T, _52: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), g(f(d, _49), g(f(d, _50), g(f(d, _51), f(d, _52))))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_1[T](f: T, g: T, d: T, _1: T) -> T {
    f(d, _1)
}
pub fn M_REDUCEI2B_2[T](f: T, g: T, d: T, _1: T, _2: T) -> T {
    g(f(d, _1), f(d, _2))
}
pub fn M_REDUCEI2B_3[T](f: T, g: T, d: T, _1: T, _2: T, _3: T) -> T {
    g(f(d, _1), g(f(d, _2), f(d, _3)))
}
pub fn M_REDUCEI2B_4[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), f(d, _4))))
}
pub fn M_REDUCEI2B_5[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), f(d, _5)))))
}
pub fn M_REDUCEI2B_6[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), f(d, _6))))))
}
pub fn M_REDUCEI2B_7[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), f(d, _7)))))))
}
pub fn M_REDUCEI2B_8[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), f(d, _8))))))))
}
pub fn M_REDUCEI2B_9[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), f(d, _9)))))))))
}
pub fn M_REDUCEI2B_10[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), f(d, _10))))))))))
}
pub fn M_REDUCEI2B_11[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), f(d, _11)))))))))))
}
pub fn M_REDUCEI2B_12[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), f(d, _12))))))))))))
}
pub fn M_REDUCEI2B_13[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), f(d, _13)))))))))))))
}
pub fn M_REDUCEI2B_14[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), f(d, _14))))))))))))))
}
pub fn M_REDUCEI2B_15[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), f(d, _15)))))))))))))))
}
pub fn M_REDUCEI2B_17[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), f(d, _17)))))))))))))))))
}
pub fn M_REDUCEI2B_18[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), f(d, _18))))))))))))))))))
}
pub fn M_REDUCEI2B_19[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), f(d, _19)))))))))))))))))))
}
pub fn M_REDUCEI2B_20[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), f(d, _20))))))))))))))))))))
}
pub fn M_REDUCEI2B_21[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), f(d, _21)))))))))))))))))))))
}
pub fn M_REDUCEI2B_22[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), f(d, _22))))))))))))))))))))))
}
pub fn M_REDUCEI2B_23[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), f(d, _23)))))))))))))))))))))))
}
pub fn M_REDUCEI2B_24[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), f(d, _24))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_25[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), f(d, _25)))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_26[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), f(d, _26))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_27[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), f(d, _27)))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_28[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), f(d, _28))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_29[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), f(d, _29)))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_30[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), f(d, _30))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_31[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), f(d, _31)))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_33[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), f(d, _33)))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_34[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), f(d, _34))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_35[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), f(d, _35)))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_36[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), f(d, _36))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_37[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), f(d, _37)))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_38[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), f(d, _38))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_39[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), f(d, _39)))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_40[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), f(d, _40))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_41[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), f(d, _41)))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_42[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), f(d, _42))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_43[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), f(d, _43)))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_44[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), f(d, _44))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_45[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), f(d, _45)))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_46[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), f(d, _46))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_47[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), f(d, _47)))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_48[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), f(d, _48))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_49[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), f(d, _49)))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_50[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), g(f(d, _49), f(d, _50))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_51[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), g(f(d, _49), g(f(d, _50), f(d, _51)))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI2B_52[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T, _52: T) -> T {
    g(f(d, _1), g(f(d, _2), g(f(d, _3), g(f(d, _4), g(f(d, _5), g(f(d, _6), g(f(d, _7), g(f(d, _8), g(f(d, _9), g(f(d, _10), g(f(d, _11), g(f(d, _12), g(f(d, _13), g(f(d, _14), g(f(d, _15), g(f(d, _16), g(f(d, _17), g(f(d, _18), g(f(d, _19), g(f(d, _20), g(f(d, _21), g(f(d, _22), g(f(d, _23), g(f(d, _24), g(f(d, _25), g(f(d, _26), g(f(d, _27), g(f(d, _28), g(f(d, _29), g(f(d, _30), g(f(d, _31), g(f(d, _32), g(f(d, _33), g(f(d, _34), g(f(d, _35), g(f(d, _36), g(f(d, _37), g(f(d, _38), g(f(d, _39), g(f(d, _40), g(f(d, _41), g(f(d, _42), g(f(d, _43), g(f(d, _44), g(f(d, _45), g(f(d, _46), g(f(d, _47), g(f(d, _48), g(f(d, _49), g(f(d, _50), g(f(d, _51), f(d, _52))))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_1[T](f: T, g: T, d: T, _1: T) -> T {
    f(d, 1, _1)
}
pub fn M_REDUCEI3_2[T](f: T, g: T, d: T, _1: T, _2: T) -> T {
    g(f(d, 1, _1), f(d, 2, _2))
}
pub fn M_REDUCEI3_3[T](f: T, g: T, d: T, _1: T, _2: T, _3: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), f(d, 3, _3)))
}
pub fn M_REDUCEI3_4[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), f(d, 4, _4))))
}
pub fn M_REDUCEI3_5[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), f(d, 5, _5)))))
}
pub fn M_REDUCEI3_6[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), f(d, 6, _6))))))
}
pub fn M_REDUCEI3_7[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), f(d, 7, _7)))))))
}
pub fn M_REDUCEI3_8[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), f(d, 8, _8))))))))
}
pub fn M_REDUCEI3_9[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), f(d, 9, _9)))))))))
}
pub fn M_REDUCEI3_10[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), f(d, 10, _10))))))))))
}
pub fn M_REDUCEI3_11[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), f(d, 11, _11)))))))))))
}
pub fn M_REDUCEI3_12[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), f(d, 12, _12))))))))))))
}
pub fn M_REDUCEI3_13[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), f(d, 13, _13)))))))))))))
}
pub fn M_REDUCEI3_14[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), f(d, 14, _14))))))))))))))
}
pub fn M_REDUCEI3_15[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), f(d, 15, _15)))))))))))))))
}
pub fn M_REDUCEI3_17[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), f(d, 17, _17)))))))))))))))))
}
pub fn M_REDUCEI3_18[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), f(d, 18, _18))))))))))))))))))
}
pub fn M_REDUCEI3_19[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), f(d, 19, _19)))))))))))))))))))
}
pub fn M_REDUCEI3_20[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), f(d, 20, _20))))))))))))))))))))
}
pub fn M_REDUCEI3_21[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), f(d, 21, _21)))))))))))))))))))))
}
pub fn M_REDUCEI3_22[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), f(d, 22, _22))))))))))))))))))))))
}
pub fn M_REDUCEI3_23[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), f(d, 23, _23)))))))))))))))))))))))
}
pub fn M_REDUCEI3_24[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), f(d, 24, _24))))))))))))))))))))))))
}
pub fn M_REDUCEI3_25[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), f(d, 25, _25)))))))))))))))))))))))))
}
pub fn M_REDUCEI3_26[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), f(d, 26, _26))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_27[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), f(d, 27, _27)))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_28[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), f(d, 28, _28))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_29[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), f(d, 29, _29)))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_30[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), f(d, 30, _30))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_31[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), f(d, 31, _31)))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_33[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), f(d, 33, _33)))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_34[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), f(d, 34, _34))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_35[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), f(d, 35, _35)))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_36[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), f(d, 36, _36))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_37[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), f(d, 37, _37)))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_38[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), f(d, 38, _38))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_39[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), f(d, 39, _39)))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_40[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), f(d, 40, _40))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_41[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), f(d, 41, _41)))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_42[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), f(d, 42, _42))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_43[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), f(d, 43, _43)))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_44[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), f(d, 44, _44))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_45[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), f(d, 45, _45)))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_46[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), g(f(d, 45, _45), f(d, 46, _46))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_47[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), g(f(d, 45, _45), g(f(d, 46, _46), f(d, 47, _47)))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_48[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), g(f(d, 45, _45), g(f(d, 46, _46), g(f(d, 47, _47), f(d, 48, _48))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_49[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), g(f(d, 45, _45), g(f(d, 46, _46), g(f(d, 47, _47), g(f(d, 48, _48), f(d, 49, _49)))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_50[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), g(f(d, 45, _45), g(f(d, 46, _46), g(f(d, 47, _47), g(f(d, 48, _48), g(f(d, 49, _49), f(d, 50, _50))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_51[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), g(f(d, 45, _45), g(f(d, 46, _46), g(f(d, 47, _47), g(f(d, 48, _48), g(f(d, 49, _49), g(f(d, 50, _50), f(d, 51, _51)))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_REDUCEI3_52[T](f: T, g: T, d: T, _1: T, _2: T, _3: T, _4: T, _5: T, _6: T, _7: T, _8: T, _9: T, _10: T, _11: T, _12: T, _13: T, _14: T, _15: T, _16: T, _17: T, _18: T, _19: T, _20: T, _21: T, _22: T, _23: T, _24: T, _25: T, _26: T, _27: T, _28: T, _29: T, _30: T, _31: T, _32: T, _33: T, _34: T, _35: T, _36: T, _37: T, _38: T, _39: T, _40: T, _41: T, _42: T, _43: T, _44: T, _45: T, _46: T, _47: T, _48: T, _49: T, _50: T, _51: T, _52: T) -> T {
    g(f(d, 1, _1), g(f(d, 2, _2), g(f(d, 3, _3), g(f(d, 4, _4), g(f(d, 5, _5), g(f(d, 6, _6), g(f(d, 7, _7), g(f(d, 8, _8), g(f(d, 9, _9), g(f(d, 10, _10), g(f(d, 11, _11), g(f(d, 12, _12), g(f(d, 13, _13), g(f(d, 14, _14), g(f(d, 15, _15), g(f(d, 16, _16), g(f(d, 17, _17), g(f(d, 18, _18), g(f(d, 19, _19), g(f(d, 20, _20), g(f(d, 21, _21), g(f(d, 22, _22), g(f(d, 23, _23), g(f(d, 24, _24), g(f(d, 25, _25), g(f(d, 26, _26), g(f(d, 27, _27), g(f(d, 28, _28), g(f(d, 29, _29), g(f(d, 30, _30), g(f(d, 31, _31), g(f(d, 32, _32), g(f(d, 33, _33), g(f(d, 34, _34), g(f(d, 35, _35), g(f(d, 36, _36), g(f(d, 37, _37), g(f(d, 38, _38), g(f(d, 39, _39), g(f(d, 40, _40), g(f(d, 41, _41), g(f(d, 42, _42), g(f(d, 43, _43), g(f(d, 44, _44), g(f(d, 45, _45), g(f(d, 46, _46), g(f(d, 47, _47), g(f(d, 48, _48), g(f(d, 49, _49), g(f(d, 50, _50), g(f(d, 51, _51), f(d, 52, _52))))))))))))))))))))))))))))))))))))))))))))))))))))
}
pub fn M_CROSSI_MAP2_F_C[T](f: T, d: T, a1: T, b1: T) -> T {
    f(d, a1, b1)
}
pub let M_NDEBUG_TEST: c_int = 0
pub fn M_AS_STRI(x: str) -> str {
    x
}
pub fn M_OPL_AS_STR(x: i32) {
    return
}
pub let M_USE_IDENTIFIER_ALLOC: c_int = 128
pub fn M_PRINTF_FORMAT_EXTEND() {
    return
}
pub fn M_MIN[T](x: T, y: T) -> T {
    (if (x < y): x else: y)
}
pub fn M_MAX[T](x: T, y: T) -> T {
    (if (x > y): x else: y)
}
pub fn M_POWEROF2_P[T](n: T) -> T {
    (if (n & (n - 1)) != 0: 0 else: 1)
}
pub fn M_ADD_SIZE[T](a: T, b: T) -> T {
    (a + b)
}
pub fn M_VLA[T](n: T) -> T {
    n
}
pub let M_USE_HASH_SEED: c_ulong = 0
pub let M_HASH_INIT: c_ulong = 0
pub fn M_HASH_CALC[T](h1: T, h2: T) -> T {
    ((h1 * 0x811C9DC5u64) ^ h2)
}
pub fn M_HASH_FINAL[T](hash: T) -> T {
    ((hash >> (((sizeof[c_ulong]() * 8) / 2) as u32)) ^ hash)
}
pub let M_USE_UNDEF_OPLIST_TERMS: c_int = 0
pub fn M_EQUAL_DEFAULT[T](a: T, b: T) -> c_int {
    ((a == b) as c_int)
}
pub fn M_CMP_DEFAULT[T](a: T, b: T) -> T {
    (if (a < b): -1 else: (a > b))
}
pub fn M_NO_EXT_ALGO(n: i32, co: i32, to: i32) {
    return
}
pub fn M_INC_ALLOC_DEFAULT[T](n: T) -> T {
    (M_MAX(8, n) * 2)
}
pub fn M_RESET_POD[T](a: T) -> i64 {
    with_memset(&a as *mut u8, 0, sizeof[T]() as i64)
}
pub fn M_CSTR_EQUAL[T](a: T, b: T) -> c_int {
    ((strcmp(a, b) == 0) as c_int)
}
pub fn M_GLOBALI_OPLIST_ID[T](a: T) -> T {
    a
}
pub fn M_LET_TRY_INJECT_PRE(cont: i32, oplist: i32, name: i32) {
    return
}
pub fn M_LET_TRY_INJECT_POST(cont: i32, oplist: i32, name: i32) {
    return
}
pub fn M_DEFER_TRY_INJECT_PRE(cont: i32, clear: i32) {
    return
}
pub fn M_DEFER_TRY_INJECT_POST(cont: i32, clear: i32) {
    return
}
pub fn M_INIT_KEY_VAI_ID[T](a: T) -> T {
    a
}
pub fn M_EMPLACE_ASS_ARRAY_DEF_EXPAND_BOTH_EMP_TYPE_LIST[T](val_emp: T) -> T {
    val_emp
}
pub let M_USE_BACKOFF_MAX_COUNT: c_int = 8
pub let M_USE_SERIAL_MAX_DATA_SIZE: c_int = 4
pub let M_BPTR33_MAX_STACK: c_int = 65
pub let M_BPTR33_TRANSACTION_MAX: c_int = 265
pub fn MLIB_SLOT_CLEAR[T](s: T) -> T {
    unsafe { mlib_slot_release(s) }
}
@[repr(C)]
pub type multimap_pair_s { pub key_ptr: *mut c_int = null, pub value_ptr: *mut c_int = null }
impl Copy for multimap_pair_s

pub type multimap_itref_t = multimap_pair_s

@[repr(C)]
pub type multimap_kind_s = union { pub value: [c_int; 6] = [0 as c_int; 6], pub node: [*mut multimap_node_s; 7] = [null as *mut multimap_node_s; 7] }
impl Copy for multimap_kind_s

@[repr(C)]
pub type multimap_node_s { pub num: c_int = 0, pub key: [c_int; 6] = [0 as c_int; 6], pub next: *mut multimap_node_s = null, pub prev: *mut multimap_node_s = null, pub kind: multimap_kind_s }
impl Copy for multimap_node_s

pub type multimap_node_ct = *mut multimap_node_s

@[repr(C)]
pub type multimap_s { pub root: *mut multimap_node_s = null, pub size: c_ulong = 0 }
impl Copy for multimap_s

pub type multimap_t = [multimap_s; 1]

pub type multimap_ptr = *mut multimap_s

pub type multimap_srcptr = *const multimap_s

pub type multimap_subtype_ct = multimap_pair_s

pub type multimap_key_ct = c_int

pub type multimap_value_ct = c_int

pub type multimap_ct = [multimap_s; 1]

@[repr(C)]
pub type multimap_parent_it_s { pub num: c_int = 0, pub parent: [*mut multimap_node_s; 65] = [null as *mut multimap_node_s; 65] }
impl Copy for multimap_parent_it_s

pub type multimap_pit_ct = [multimap_parent_it_s; 1]

@[repr(C)]
pub type multimap_it_s { pub pair: multimap_pair_s, pub node: *mut multimap_node_s = null, pub idx: c_int = 0 }
impl Copy for multimap_it_s

pub type multimap_it_t = [multimap_it_s; 1]

pub type multimap_it_ct = [multimap_it_s; 1]
