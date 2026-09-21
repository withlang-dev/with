// std.zl.defs — shared definitions for migrated PCRE2

pub fn is_alpha(c: i32) -> bool {
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
}
pub fn is_digit(c: i32) -> bool {
    c >= 48 and c <= 57
}
pub fn is_space(c: i32) -> bool {
    c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11
}
pub fn is_alnum(c: i32) -> bool {
    is_alpha(c) or is_digit(c)
}
pub fn is_upper(c: i32) -> bool {
    c >= 65 and c <= 90
}
pub fn is_lower(c: i32) -> bool {
    c >= 97 and c <= 122
}
pub fn is_xdigit(c: i32) -> bool {
    (c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)
}
pub fn is_print(c: i32) -> bool {
    c >= 32 and c <= 126
}
pub fn to_lower(c: i32) -> i32 {
    if c >= 65 and c <= 90 { c + 32 } else { c }
}
pub fn to_upper(c: i32) -> i32 {
    if c >= 97 and c <= 122 { c - 32 } else { c }
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
pub unsafe fn __with_builtin_add_overflow_i8(a: i8, b: i8, out: *mut i8) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i8(a: i8, b: i8, out: *mut i8) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i8(a: i8, b: i8, out: *mut i8) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u8(a: u8, b: u8, out: *mut u8) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u8(a: u8, b: u8, out: *mut u8) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u8(a: u8, b: u8, out: *mut u8) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i16(a: i16, b: i16, out: *mut i16) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i16(a: i16, b: i16, out: *mut i16) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i16(a: i16, b: i16, out: *mut i16) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u16(a: u16, b: u16, out: *mut u16) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u16(a: u16, b: u16, out: *mut u16) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u16(a: u16, b: u16, out: *mut u16) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i32(a: i32, b: i32, out: *mut i32) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i32(a: i32, b: i32, out: *mut i32) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i32(a: i32, b: i32, out: *mut i32) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u32(a: u32, b: u32, out: *mut u32) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u32(a: u32, b: u32, out: *mut u32) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u32(a: u32, b: u32, out: *mut u32) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i64(a: i64, b: i64, out: *mut i64) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i64(a: i64, b: i64, out: *mut i64) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i64(a: i64, b: i64, out: *mut i64) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u64(a: u64, b: u64, out: *mut u64) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u64(a: u64, b: u64, out: *mut u64) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u64(a: u64, b: u64, out: *mut u64) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i128(a: i128, b: i128, out: *mut i128) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i128(a: i128, b: i128, out: *mut i128) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
// The 128-bit overflow checks stay division-free on purpose: `/` on i128/u128
// lowers to the __divti3/__udivti3 compiler-rt libcalls, and this shim is
// compiled into freestanding runtime objects whose COFF link has no builtins
// library to resolve them from. Limb decomposition keeps the check to multiplies
// and shifts, which lower inline on every target and at every -O level.
pub fn u128_mul_would_overflow(a: u128, b: u128) -> bool {
    let a_hi = (a >> 64) as u64
    let b_hi = (b >> 64) as u64
    if a_hi != 0 and b_hi != 0: return true
    let a_lo = (a as u64) as u128
    let b_lo = (b as u64) as u128
    let cross = (a_hi as u128) *% b_lo +% (b_hi as u128) *% a_lo
    if (cross >> 64) != 0: return true
    let low = a_lo *% b_lo
    ((low >> 64) +% cross) >> 64 != 0
}
pub unsafe fn __with_builtin_mul_overflow_i128(a: i128, b: i128, out: *mut i128) -> bool {
    unsafe { (*out = a *% b) }
    if a == 0 or b == 0: return false
    let neg = (a < 0) != (b < 0)
    let ua = if a < 0: (0 as u128) -% (a as u128) else: a as u128
    let ub = if b < 0: (0 as u128) -% (b as u128) else: b as u128
    if u128_mul_would_overflow(ua, ub): return true
    let limit = if neg: (1 as u128) << 127 else: ((1 as u128) << 127) -% 1
    ua *% ub > limit
}
pub unsafe fn __with_builtin_add_overflow_u128(a: u128, b: u128, out: *mut u128) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u128(a: u128, b: u128, out: *mut u128) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u128(a: u128, b: u128, out: *mut u128) -> bool {
    unsafe { (*out = a *% b) }
    u128_mul_would_overflow(a, b)
}
pub extern fn with_clz(x: i32) -> i32
pub extern fn with_ctz(x: i32) -> i32
pub extern fn with_popcount(x: i32) -> i32
pub extern fn with_bswap16(x: u16) -> u16
pub extern fn with_bswap32(x: u32) -> u32
pub extern fn with_bswap64(x: u64) -> u64
pub extern fn with_clzl(x: i64) -> i32
pub extern fn with_clzll(x: i64) -> i32
pub extern fn with_ctzl(x: i64) -> i32
pub extern fn with_ctzll(x: i64) -> i32
pub extern fn with_abs(x: i32) -> i32
pub extern fn with_alloc(size: i64) -> *mut u8
pub extern fn with_alloc_zeroed(count: i64, size: i64) -> *mut u8
pub extern fn with_realloc(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8
pub extern fn with_free(ptr: *mut u8) -> Unit
pub extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
pub extern fn with_memmove(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
pub extern fn with_memset(dst: *mut u8, c: i32, n: i64) -> *mut u8
pub extern fn with_memcmp(a: *const u8, b: *const u8, n: i64) -> i32
pub extern fn with_va_start(ap: *mut i8) -> Unit
pub extern fn with_va_end(ap: *mut i8) -> Unit


pub type z_size_t = c_ulong

pub type Byte = u8

pub type uInt = c_uint

pub type uLong = c_ulong

pub type Bytef = u8

pub type charf = c_char

pub type intf = c_int

pub type uIntf = c_uint

pub type uLongf = c_ulong

pub type voidpc = *const c_void

pub type voidpf = *mut c_void

pub type voidp = *mut c_void

pub type z_crc_t = c_uint

pub type alloc_func = unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void

pub type free_func = unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit

pub type internal_state { strm: *mut z_stream_s = null, status: c_int = 0, pending_buf: *mut u8 = null, pending_buf_size: c_ulong = 0, pending_out: *mut u8 = null, pending: c_ulong = 0, wrap: c_int = 0, gzhead: *mut gz_header_s = null, gzindex: c_ulong = 0, method: u8 = 0, last_flush: c_int = 0, w_size: c_uint = 0, w_bits: c_uint = 0, w_mask: c_uint = 0, window: *mut u8 = null, window_size: c_ulong = 0, prev: *mut c_ushort = null, head: *mut c_ushort = null, ins_h: c_uint = 0, hash_size: c_uint = 0, hash_bits: c_uint = 0, hash_mask: c_uint = 0, hash_shift: c_uint = 0, block_start: c_long = 0, match_length: c_uint = 0, prev_match: c_uint = 0, match_available: c_int = 0, strstart: c_uint = 0, match_start: c_uint = 0, lookahead: c_uint = 0, prev_length: c_uint = 0, max_chain_length: c_uint = 0, max_lazy_match: c_uint = 0, level: c_int = 0, strategy: c_int = 0, good_match: c_uint = 0, nice_match: c_int = 0, dyn_ltree: [573]ct_data_s, dyn_dtree: [61]ct_data_s, bl_tree: [39]ct_data_s, l_desc: tree_desc_s, d_desc: tree_desc_s, bl_desc: tree_desc_s, bl_count: [16]c_ushort = [0 as c_ushort; 16], heap: [573]c_int = [0 as c_int; 573], heap_len: c_int = 0, heap_max: c_int = 0, depth: [573]u8 = [0 as u8; 573], sym_buf: *mut u8 = null, lit_bufsize: c_uint = 0, sym_next: c_uint = 0, sym_end: c_uint = 0, opt_len: c_ulong = 0, static_len: c_ulong = 0, matches: c_uint = 0, insert: c_uint = 0, bi_buf: c_ushort = 0, bi_valid: c_int = 0, bi_used: c_int = 0, high_water: c_ulong = 0, slid: c_int = 0 }
impl Copy for internal_state

pub type z_stream_s { next_in: *mut u8 = null, avail_in: c_uint = 0, total_in: c_ulong = 0, next_out: *mut u8 = null, avail_out: c_uint = 0, total_out: c_ulong = 0, msg: *mut i8 = null, state: *mut internal_state = null, zalloc: unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void, zfree: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, opaque_: *mut c_void = null, data_type: c_int = 0, adler: c_ulong = 0, reserved: c_ulong = 0 }
impl Copy for z_stream_s

pub type z_stream = z_stream_s

pub type z_streamp = *mut z_stream_s

pub type gz_header_s { text: c_int = 0, time: c_ulong = 0, xflags: c_int = 0, os: c_int = 0, extra: *mut u8 = null, extra_len: c_uint = 0, extra_max: c_uint = 0, name: *mut u8 = null, name_max: c_uint = 0, comment: *mut u8 = null, comm_max: c_uint = 0, hcrc: c_int = 0, done: c_int = 0 }
impl Copy for gz_header_s

pub type gz_header = gz_header_s

pub type gz_headerp = *mut gz_header_s

pub type in_func = unsafe extern "C" fn(*mut c_void, *mut *mut u8) -> c_uint

pub type out_func = unsafe extern "C" fn(*mut c_void, *mut u8, c_uint) -> c_int

pub type gzFile = *mut gzFile_s

pub type gzFile_s { have: c_uint = 0, next: *mut u8 = null, pos: c_longlong = 0 }
impl Copy for gzFile_s

pub type uch = u8

pub type uchf = u8

pub type ush = c_ushort

pub type ushf = c_ushort

pub type ulg = c_ulong

pub let MAX_MEM_LEVEL: c_int = 9
pub let MAX_WBITS: c_int = 15
pub fn OF[T](args: T) -> T {
    args
}
pub let ZLIB_VERSION = "1.3.2"
pub let ZLIB_VERNUM: c_int = 0x1320
pub let ZLIB_VER_MAJOR: c_int = 1
pub let ZLIB_VER_MINOR: c_int = 3
pub let ZLIB_VER_REVISION: c_int = 2
pub let ZLIB_VER_SUBREVISION: c_int = 0
pub let Z_NO_FLUSH: c_int = 0
pub let Z_PARTIAL_FLUSH: c_int = 1
pub let Z_SYNC_FLUSH: c_int = 2
pub let Z_FULL_FLUSH: c_int = 3
pub let Z_FINISH: c_int = 4
pub let Z_BLOCK: c_int = 5
pub let Z_TREES: c_int = 6
pub let Z_OK: c_int = 0
pub let Z_STREAM_END: c_int = 1
pub let Z_NEED_DICT: c_int = 2
pub let Z_ERRNO: c_int = -1
pub let Z_STREAM_ERROR: c_int = -2
pub let Z_DATA_ERROR: c_int = -3
pub let Z_MEM_ERROR: c_int = -4
pub let Z_BUF_ERROR: c_int = -5
pub let Z_VERSION_ERROR: c_int = -6
pub let Z_NO_COMPRESSION: c_int = 0
pub let Z_BEST_SPEED: c_int = 1
pub let Z_BEST_COMPRESSION: c_int = 9
pub let Z_DEFAULT_COMPRESSION: c_int = -1
pub let Z_FILTERED: c_int = 1
pub let Z_HUFFMAN_ONLY: c_int = 2
pub let Z_RLE: c_int = 3
pub let Z_FIXED: c_int = 4
pub let Z_DEFAULT_STRATEGY: c_int = 0
pub let Z_BINARY: c_int = 0
pub let Z_TEXT: c_int = 1
pub let Z_ASCII: c_int = 1
pub let Z_UNKNOWN: c_int = 2
pub let Z_DEFLATED: c_int = 8
pub let Z_NULL: c_int = 0
pub let DEF_WBITS: c_int = 15
pub let DEF_MEM_LEVEL: c_int = 8
pub let STORED_BLOCK: c_int = 0
pub let STATIC_TREES: c_int = 1
pub let DYN_TREES: c_int = 2
pub let MIN_MATCH: c_int = 3
pub let MAX_MATCH: c_int = 258
pub let PRESET_DICT: c_int = 0x20
pub let OS_CODE: c_int = 19
pub fn Assert(cond: i32, msg: i32) -> Unit {
    return
}
pub fn Trace(x: i32) -> Unit {
    return
}
pub fn Tracev(x: i32) -> Unit {
    return
}
pub fn Tracevv(x: i32) -> Unit {
    return
}
pub fn Tracec(c: i32, x: i32) -> Unit {
    return
}
pub fn Tracecv(c: i32, x: i32) -> Unit {
    return
}
pub fn ZSWAP32[T](q: T) -> T {
    (((((q >> 24) & 0xff) + ((q >> 8) & 0xff00)) + ((q & 0xff00) << 8)) + ((q & 0xff) << 24))
}
pub let BASE: c_uint = 65521
pub let NMAX: c_int = 5552
pub type z_word_t = c_ulong

pub let N: c_int = 5
pub let W: c_int = 8
pub let POLY: c_uint = 0xedb88320
pub type ct_data_s_fc = union { freq: c_ushort = 0, code: c_ushort = 0 }
impl Copy for ct_data_s_fc
pub type ct_data_s_dl = union { dad: c_ushort = 0, len: c_ushort = 0 }
impl Copy for ct_data_s_dl
pub type ct_data_s { fc: ct_data_s_fc, dl: ct_data_s_dl }
impl Copy for ct_data_s

pub type ct_data = ct_data_s

pub type static_tree_desc_s { static_tree: *const ct_data_s = null, extra_bits: *const c_int = null, extra_base: c_int = 0, elems: c_int = 0, max_length: c_int = 0 }
impl Copy for static_tree_desc_s

pub type static_tree_desc = static_tree_desc_s

pub type tree_desc_s { dyn_tree: *mut ct_data_s = null, max_code: c_int = 0, stat_desc: *const static_tree_desc_s = null }
impl Copy for tree_desc_s

pub type tree_desc = tree_desc_s

pub type Pos = c_ushort

pub type Posf = c_ushort

pub type IPos = c_uint

pub type deflate_state = internal_state

pub type block_state = c_uint

pub let need_more: c_uint = 0
pub let block_done: c_uint = 1
pub let finish_started: c_uint = 2
pub let finish_done: c_uint = 3
pub type compress_func = unsafe extern "C" fn(*mut internal_state, c_int) -> i32

pub type config_s { good_length: c_ushort = 0, max_lazy: c_ushort = 0, nice_length: c_ushort = 0, max_chain: c_ushort = 0, func: unsafe extern "C" fn(*mut internal_state, c_int) -> i32 }
impl Copy for config_s

pub type config = config_s

pub let deflate_copyright: [68]c_char = [32, 100, 101, 102, 108, 97, 116, 101, 32, 49, 46, 51, 46, 50, 32, 67, 111, 112, 121, 114, 105, 103, 104, 116, 32, 49, 57, 57, 53, 45, 50, 48, 50, 54, 32, 74, 101, 97, 110, 45, 108, 111, 117, 112, 32, 71, 97, 105, 108, 108, 121, 32, 97, 110, 100, 32, 77, 97, 114, 107, 32, 65, 100, 108, 101, 114, 32, 0]

pub fn deflateInit[T](strm: T, level: T) -> T {
    unsafe { deflateInit_(strm, level, ZLIB_VERSION, (sizeof[z_stream_s]() as c_int)) }
}
pub fn deflateInit2[T](strm: T, level: T, method: T, windowBits: T, memLevel: T, strategy: T) -> T {
    unsafe { deflateInit2_(strm, level, method, windowBits, memLevel, strategy, ZLIB_VERSION, (sizeof[z_stream_s]() as c_int)) }
}
pub let LENGTH_CODES: c_int = 29
pub let LITERALS: c_int = 256
pub let L_CODES: c_int = ((256 + 1) + 29)
pub let D_CODES: c_int = 30
pub let BL_CODES: c_int = 19
pub let HEAP_SIZE: c_int = ((2 * L_CODES) + 1)
pub let MAX_BITS: c_int = 15
pub let Buf_size: c_int = 16
pub let INIT_STATE: c_int = 42
pub let GZIP_STATE: c_int = 57
pub let EXTRA_STATE: c_int = 69
pub let NAME_STATE: c_int = 73
pub let COMMENT_STATE: c_int = 91
pub let HCRC_STATE: c_int = 103
pub let BUSY_STATE: c_int = 113
pub let FINISH_STATE: c_int = 666
pub let LIT_BUFS: c_int = 4
pub let MIN_LOOKAHEAD: c_int = ((258 + 3) + 1)
pub let WIN_INIT: c_int = 258
pub fn d_code[T](dist: T) -> T {
    (if (dist < 256): _dist_code[dist] else: _dist_code[(256 + (dist >> 7))])
}
pub let NIL: c_int = 0
pub let TOO_FAR: c_int = 4096
pub fn RANK[T](f: T) -> T {
    ((f * 2) - (if (f > 4): 9 else: 0))
}
pub fn check_match(s: i32, start: i32, match_: i32, length: i32) -> Unit {
    return
}
pub let MAX_STORED: c_int = 65535
pub fn MIN[T](a: T, b: T) -> T {
    (if (a > b): b else: a)
}
pub type gz_state { x: gzFile_s, mode: c_int = 0, fd: c_int = 0, path: *mut i8 = null, size: c_uint = 0, want: c_uint = 0, in_: *mut u8 = null, out: *mut u8 = null, direct: c_int = 0, junk: c_int = 0, how: c_int = 0, again: c_int = 0, start: c_longlong = 0, eof: c_int = 0, past: c_int = 0, level: c_int = 0, strategy: c_int = 0, reset: c_int = 0, skip: c_longlong = 0, err: c_int = 0, msg: *mut i8 = null, strm: z_stream_s }
impl Copy for gz_state

pub type gz_statep = *mut gz_state

pub let GZBUFSIZE: c_int = 8192
pub let GZ_NONE: c_int = 0
pub let GZ_READ: c_int = 7247
pub let GZ_WRITE: c_int = 31153
pub let GZ_APPEND: c_int = 1
pub let LOOK: c_int = 0
pub let COPY: c_int = 1
pub let GZIP: c_int = 2
pub fn GT_OFF[T](x: T) -> T {
    sizeof[c_int]()
}
pub type code { op: u8 = 0, bits: u8 = 0, val: c_ushort = 0 }
impl Copy for code

pub type codetype = c_uint

pub let CODES: c_uint = 0
pub let LENS: c_uint = 1
pub let DISTS: c_uint = 2
pub type inflate_mode = c_uint

pub let HEAD: c_uint = 16180
pub let FLAGS: c_uint = 16181
pub let TIME: c_uint = 16182
pub let OS: c_uint = 16183
pub let EXLEN: c_uint = 16184
pub let EXTRA: c_uint = 16185
pub let NAME: c_uint = 16186
pub let COMMENT: c_uint = 16187
pub let HCRC: c_uint = 16188
pub let DICTID: c_uint = 16189
pub let DICT: c_uint = 16190
pub let TYPE: c_uint = 16191
pub let TYPEDO: c_uint = 16192
pub let STORED: c_uint = 16193
pub let COPY_: c_uint = 16194
pub let TABLE: c_uint = 16196
pub let LENLENS: c_uint = 16197
pub let CODELENS: c_uint = 16198
pub let LEN_: c_uint = 16199
pub let LEN: c_uint = 16200
pub let LENEXT: c_uint = 16201
pub let DIST: c_uint = 16202
pub let DISTEXT: c_uint = 16203
pub let MATCH: c_uint = 16204
pub let LIT: c_uint = 16205
pub let CHECK: c_uint = 16206
pub let LENGTH: c_uint = 16207
pub let DONE: c_uint = 16208
pub let BAD: c_uint = 16209
pub let MEM: c_uint = 16210
pub let SYNC: c_uint = 16211
pub type inflate_state { strm: *mut z_stream_s = null, mode: i32 = 0, last: c_int = 0, wrap: c_int = 0, havedict: c_int = 0, flags: c_int = 0, dmax: c_uint = 0, check_: c_ulong = 0, total: c_ulong = 0, head: *mut gz_header_s = null, wbits: c_uint = 0, wsize: c_uint = 0, whave: c_uint = 0, wnext: c_uint = 0, window: *mut u8 = null, hold: c_ulong = 0, bits: c_uint = 0, length: c_uint = 0, offset: c_uint = 0, extra: c_uint = 0, lencode: *const code = null, distcode: *const code = null, lenbits: c_uint = 0, distbits: c_uint = 0, ncode: c_uint = 0, nlen: c_uint = 0, ndist: c_uint = 0, have: c_uint = 0, next: *mut code = null, lens: [320]c_ushort = [0 as c_ushort; 320], work: [288]c_ushort = [0 as c_ushort; 288], codes: [1444]code, sane: c_int = 0, back: c_int = 0, was: c_uint = 0 }
impl Copy for inflate_state

pub fn inflateBackInit[T](strm: T, windowBits: T, window: T) -> T {
    unsafe { inflateBackInit_(strm, windowBits, window, ZLIB_VERSION, (sizeof[z_stream_s]() as c_int)) }
}
pub let ENOUGH_LENS: c_int = 852
pub let ENOUGH_DISTS: c_int = 592
pub let ENOUGH: c_int = 1444
pub fn inflateInit[T](strm: T) -> T {
    unsafe { inflateInit_(strm, ZLIB_VERSION, (sizeof[z_stream_s]() as c_int)) }
}
pub fn inflateInit2[T](strm: T, windowBits: T) -> T {
    unsafe { inflateInit2_(strm, windowBits, ZLIB_VERSION, (sizeof[z_stream_s]() as c_int)) }
}
pub let inflate_copyright: [47]c_char = [32, 105, 110, 102, 108, 97, 116, 101, 32, 49, 46, 51, 46, 50, 32, 67, 111, 112, 121, 114, 105, 103, 104, 116, 32, 49, 57, 57, 53, 45, 50, 48, 50, 54, 32, 77, 97, 114, 107, 32, 65, 100, 108, 101, 114, 32, 0]

pub let MAXBITS: c_int = 15
pub type i8_t = c_char

pub type ui8_t = u8

pub type i16_t = c_short

pub type ui16_t = c_ushort

pub type i32_t = c_int

pub type ui32_t = c_uint

pub type i64_t = c_long

pub type ui64_t = c_ulong

pub type ZPOS64_T = c_ulong

pub type open_file_func = unsafe extern "C" fn(*mut c_void, *const i8, c_int) -> *mut c_void

pub type read_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void, *mut c_void, c_ulong) -> c_ulong

pub type write_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void, *const c_void, c_ulong) -> c_ulong

pub type close_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type testerror_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int

pub type tell_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_long

pub type seek_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void, c_ulong, c_int) -> c_long

pub type zlib_filefunc_def_s { zopen_file: unsafe extern "C" fn(*mut c_void, *const i8, c_int) -> *mut c_void, zread_file: unsafe extern "C" fn(*mut c_void, *mut c_void, *mut c_void, c_ulong) -> c_ulong, zwrite_file: unsafe extern "C" fn(*mut c_void, *mut c_void, *const c_void, c_ulong) -> c_ulong, ztell_file: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_long, zseek_file: unsafe extern "C" fn(*mut c_void, *mut c_void, c_ulong, c_int) -> c_long, zclose_file: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, zerror_file: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, opaque_: *mut c_void = null }
impl Copy for zlib_filefunc_def_s

pub type zlib_filefunc_def = zlib_filefunc_def_s

pub type tell64_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_ulong

pub type seek64_file_func = unsafe extern "C" fn(*mut c_void, *mut c_void, c_ulong, c_int) -> c_long

pub type open64_file_func = unsafe extern "C" fn(*mut c_void, *const c_void, c_int) -> *mut c_void

pub type zlib_filefunc64_def_s { zopen64_file: unsafe extern "C" fn(*mut c_void, *const c_void, c_int) -> *mut c_void, zread_file: unsafe extern "C" fn(*mut c_void, *mut c_void, *mut c_void, c_ulong) -> c_ulong, zwrite_file: unsafe extern "C" fn(*mut c_void, *mut c_void, *const c_void, c_ulong) -> c_ulong, ztell64_file: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_ulong, zseek64_file: unsafe extern "C" fn(*mut c_void, *mut c_void, c_ulong, c_int) -> c_long, zclose_file: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, zerror_file: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, opaque_: *mut c_void = null }
impl Copy for zlib_filefunc64_def_s

pub type zlib_filefunc64_def = zlib_filefunc64_def_s

pub type zlib_filefunc64_32_def_s { zfile_func64: zlib_filefunc64_def_s, zopen32_file: unsafe extern "C" fn(*mut c_void, *const i8, c_int) -> *mut c_void, ztell32_file: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_long, zseek32_file: unsafe extern "C" fn(*mut c_void, *mut c_void, c_ulong, c_int) -> c_long }
impl Copy for zlib_filefunc64_32_def_s

pub type zlib_filefunc64_32_def = zlib_filefunc64_32_def_s

pub let PI32 = "d"
pub let PUI32 = "u"
pub let PI64 = "ld"
pub let PUI64 = "lu"
pub let MAXU32: c_uint = 0xffffffff
pub let ZLIB_FILEFUNC_SEEK_CUR: c_int = 1
pub let ZLIB_FILEFUNC_SEEK_END: c_int = 2
pub let ZLIB_FILEFUNC_SEEK_SET: c_int = 0
pub let ZLIB_FILEFUNC_MODE_READ: c_int = 1
pub let ZLIB_FILEFUNC_MODE_WRITE: c_int = 2
pub let ZLIB_FILEFUNC_MODE_READWRITEFILTER: c_int = 3
pub let ZLIB_FILEFUNC_MODE_EXISTING: c_int = 4
pub let ZLIB_FILEFUNC_MODE_CREATE: c_int = 8
pub fn ZOPEN64[T](filefunc: T, filename: T, mode: T) -> T {
    unsafe { call_zopen64(&filefunc, filename, mode) }
}
pub fn ZTELL64[T](filefunc: T, filestream: T) -> T {
    unsafe { call_ztell64(&filefunc, filestream) }
}
pub fn ZSEEK64[T](filefunc: T, filestream: T, pos: T, mode: T) -> T {
    unsafe { call_zseek64(&filefunc, filestream, pos, mode) }
}
pub type unzFile = *mut c_void

pub type tm_unz_s { tm_sec: c_int = 0, tm_min: c_int = 0, tm_hour: c_int = 0, tm_mday: c_int = 0, tm_mon: c_int = 0, tm_year: c_int = 0 }
impl Copy for tm_unz_s

pub type tm_unz = tm_unz_s

pub type unz_global_info64_s { number_entry: c_ulong = 0, size_comment: c_ulong = 0 }
impl Copy for unz_global_info64_s

pub type unz_global_info64 = unz_global_info64_s

pub type unz_global_info_s { number_entry: c_ulong = 0, size_comment: c_ulong = 0 }
impl Copy for unz_global_info_s

pub type unz_global_info = unz_global_info_s

pub type unz_file_info64_s { version: c_ulong = 0, version_needed: c_ulong = 0, flag: c_ulong = 0, compression_method: c_ulong = 0, dosDate: c_ulong = 0, crc: c_ulong = 0, compressed_size: c_ulong = 0, uncompressed_size: c_ulong = 0, size_filename: c_ulong = 0, size_file_extra: c_ulong = 0, size_file_comment: c_ulong = 0, disk_num_start: c_ulong = 0, internal_fa: c_ulong = 0, external_fa: c_ulong = 0, tmu_date: tm_unz_s }
impl Copy for unz_file_info64_s

pub type unz_file_info64 = unz_file_info64_s

pub type unz_file_info_s { version: c_ulong = 0, version_needed: c_ulong = 0, flag: c_ulong = 0, compression_method: c_ulong = 0, dosDate: c_ulong = 0, crc: c_ulong = 0, compressed_size: c_ulong = 0, uncompressed_size: c_ulong = 0, size_filename: c_ulong = 0, size_file_extra: c_ulong = 0, size_file_comment: c_ulong = 0, disk_num_start: c_ulong = 0, internal_fa: c_ulong = 0, external_fa: c_ulong = 0, tmu_date: tm_unz_s }
impl Copy for unz_file_info_s

pub type unz_file_info = unz_file_info_s

pub type unz_file_pos_s { pos_in_zip_directory: c_ulong = 0, num_of_file: c_ulong = 0 }
impl Copy for unz_file_pos_s

pub type unz_file_pos = unz_file_pos_s

pub type unz64_file_pos_s { pos_in_zip_directory: c_ulong = 0, num_of_file: c_ulong = 0 }
impl Copy for unz64_file_pos_s

pub type unz64_file_pos = unz64_file_pos_s

pub let Z_BZIP2ED: c_int = 12
pub let UNZ_OK: c_int = 0
pub let UNZ_END_OF_LIST_OF_FILE: c_int = -100
pub let UNZ_ERRNO: c_int = -1
pub let UNZ_EOF: c_int = 0
pub let UNZ_PARAMERROR: c_int = -102
pub let UNZ_BADZIPFILE: c_int = -103
pub let UNZ_INTERNALERROR: c_int = -104
pub let UNZ_CRCERROR: c_int = -105
pub fn READ_8[T](adr: T) -> u8 {
    ((unsafe *adr) as u8)
}
pub let _dist_code: [512]u8 = [(0 as u8), (1 as u8), (2 as u8), (3 as u8), (4 as u8), (4 as u8), (5 as u8), (5 as u8), (6 as u8), (6 as u8), (6 as u8), (6 as u8), (7 as u8), (7 as u8), (7 as u8), (7 as u8), (8 as u8), (8 as u8), (8 as u8), (8 as u8), (8 as u8), (8 as u8), (8 as u8), (8 as u8), (9 as u8), (9 as u8), (9 as u8), (9 as u8), (9 as u8), (9 as u8), (9 as u8), (9 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (10 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (11 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (0 as u8), (0 as u8), (16 as u8), (17 as u8), (18 as u8), (18 as u8), (19 as u8), (19 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (28 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8), (29 as u8)]

pub let _length_code: [256]u8 = [(0 as u8), (1 as u8), (2 as u8), (3 as u8), (4 as u8), (5 as u8), (6 as u8), (7 as u8), (8 as u8), (8 as u8), (9 as u8), (9 as u8), (10 as u8), (10 as u8), (11 as u8), (11 as u8), (12 as u8), (12 as u8), (12 as u8), (12 as u8), (13 as u8), (13 as u8), (13 as u8), (13 as u8), (14 as u8), (14 as u8), (14 as u8), (14 as u8), (15 as u8), (15 as u8), (15 as u8), (15 as u8), (16 as u8), (16 as u8), (16 as u8), (16 as u8), (16 as u8), (16 as u8), (16 as u8), (16 as u8), (17 as u8), (17 as u8), (17 as u8), (17 as u8), (17 as u8), (17 as u8), (17 as u8), (17 as u8), (18 as u8), (18 as u8), (18 as u8), (18 as u8), (18 as u8), (18 as u8), (18 as u8), (18 as u8), (19 as u8), (19 as u8), (19 as u8), (19 as u8), (19 as u8), (19 as u8), (19 as u8), (19 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (20 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (21 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (22 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (23 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (24 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (25 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (26 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (27 as u8), (28 as u8)]

pub let MAX_BL_BITS: c_int = 7
pub let END_BLOCK: c_int = 256
pub let REP_3_6: c_int = 16
pub let REPZ_3_10: c_int = 17
pub let REPZ_11_138: c_int = 18
pub let DIST_CODE_LEN: c_int = 512
pub let SMALLEST: c_int = 1
pub fn smaller[T](tree: T, n: T, m: T, depth: T) -> T {
    ((tree[n].Freq < tree[m].Freq) or ((tree[n].Freq == tree[m].Freq) and (depth[n] <= depth[m])))
}
pub type unz_file_info64_internal_s { offset_curfile: c_ulong = 0 }
impl Copy for unz_file_info64_internal_s

pub type unz_file_info64_internal = unz_file_info64_internal_s

pub type file_in_zip64_read_info_s { read_buffer: *mut i8 = null, stream: z_stream_s, pos_in_zipfile: c_ulong = 0, stream_initialised: c_ulong = 0, offset_local_extrafield: c_ulong = 0, size_local_extrafield: c_uint = 0, pos_local_extrafield: c_ulong = 0, total_out_64: c_ulong = 0, crc32: c_ulong = 0, crc32_wait: c_ulong = 0, rest_read_compressed: c_ulong = 0, rest_read_uncompressed: c_ulong = 0, z_filefunc: zlib_filefunc64_32_def_s, filestream: *mut c_void = null, compression_method: c_ulong = 0, byte_before_the_zipfile: c_ulong = 0, raw: c_int = 0 }
impl Copy for file_in_zip64_read_info_s

pub type unz64_s { z_filefunc: zlib_filefunc64_32_def_s, is64bitOpenFunction: c_int = 0, filestream: *mut c_void = null, gi: unz_global_info64_s, byte_before_the_zipfile: c_ulong = 0, num_file: c_ulong = 0, pos_in_central_dir: c_ulong = 0, current_file_ok: c_ulong = 0, central_pos: c_ulong = 0, size_central_dir: c_ulong = 0, offset_central_dir: c_ulong = 0, cur_file_info: unz_file_info64_s, cur_file_info_internal: unz_file_info64_internal_s, pfile_in_zip_read: *mut file_in_zip64_read_info_s = null, encrypted: c_int = 0, isZip64: c_int = 0, keys: [3]c_ulong = [0 as c_ulong; 3], pcrc_32_tab: *const c_uint = null }
impl Copy for unz64_s

pub let unz_copyright: [95]c_char = [32, 117, 110, 122, 105, 112, 32, 49, 46, 48, 49, 32, 67, 111, 112, 121, 114, 105, 103, 104, 116, 32, 49, 57, 57, 56, 45, 50, 48, 48, 52, 32, 71, 105, 108, 108, 101, 115, 32, 86, 111, 108, 108, 97, 110, 116, 32, 45, 32, 104, 116, 116, 112, 115, 58, 47, 47, 119, 119, 119, 46, 119, 105, 110, 105, 109, 97, 103, 101, 46, 99, 111, 109, 47, 122, 76, 105, 98, 68, 108, 108, 47, 109, 105, 110, 105, 122, 105, 112, 46, 104, 116, 109, 108, 0]

pub let UNZ_BUFSIZE: c_int = 16384
pub let UNZ_MAXFILENAMEINZIP: c_int = 256
pub fn ALLOC[T](size: T) -> *mut c_void {
    (unsafe { with_alloc((size) as i64) } as *mut c_void)
}
pub let SIZECENTRALDIRITEM: c_int = 0x2e
pub let SIZEZIPLOCALHEADER: c_int = 0x1e
pub let CASESENSITIVITYDEFAULTVALUE: c_int = 2
pub let BUFREADCOMMENT: c_int = 0x400
pub let CENTRALDIRINVALID: c_ulong = ((0 as c_ulong) -% 1)
pub let z_errmsg: [10]*mut i8 = [("need dictionary" as *mut c_char), ("stream end" as *mut c_char), ("" as *mut c_char), ("file error" as *mut c_char), ("stream error" as *mut c_char), ("data error" as *mut c_char), ("insufficient memory" as *mut c_char), ("buffer error" as *mut c_char), ("incompatible version" as *mut c_char), ("" as *mut c_char)]
