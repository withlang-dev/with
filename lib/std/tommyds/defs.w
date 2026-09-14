// std.tommyds.defs — shared definitions for migrated PCRE2

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


pub type tommy_uint32_t = c_uint

pub type tommy_uint64_t = c_ulonglong

pub type tommy_uintptr_t = c_ulong

pub type tommy_size_t = c_ulonglong

pub type tommy_ssize_t = c_longlong

pub type tommy_ptrdiff_t = c_long

pub type tommy_bool_t = c_int

pub type tommy_uint_t = c_uint

pub type tommy_key_t = c_ulonglong

pub type tommy_hash_t = c_ulonglong

pub type tommy_node_struct { next: *mut tommy_node_struct = null, prev: *mut tommy_node_struct = null, data: *mut c_void = null, index: c_ulonglong = 0 }
impl Copy for tommy_node_struct

pub type tommy_node = tommy_node_struct

pub type tommy_compare_func = unsafe extern "C" fn(*const c_void, *const c_void) -> c_int

pub type tommy_search_func = unsafe extern "C" fn(*const c_void, *const c_void) -> c_int

pub type tommy_foreach_func = unsafe extern "C" fn(*mut c_void) -> Unit

pub type tommy_foreach_arg_func = unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit

pub type tommy_allocator_entry_struct { next: *mut tommy_allocator_entry_struct = null }
impl Copy for tommy_allocator_entry_struct

pub type tommy_allocator_entry = tommy_allocator_entry_struct

pub type tommy_allocator_struct { free_block: *mut tommy_allocator_entry_struct = null, used_segment: *mut tommy_allocator_entry_struct = null, block_size: c_ulonglong = 0, align_size: c_ulonglong = 0, count: c_ulonglong = 0 }
impl Copy for tommy_allocator_struct

pub type tommy_allocator = tommy_allocator_struct

pub type tommy_array_struct { bucket: [64]*mut *mut c_void = [null as *mut *mut c_void; 64], bucket_max: c_ulonglong = 0, count: c_ulonglong = 0, bucket_bit: c_uint = 0 }
impl Copy for tommy_array_struct

pub type tommy_array = tommy_array_struct

pub type tommy_arrayof_struct { bucket: [64]*mut c_void = [null as *mut c_void; 64], element_size: c_ulonglong = 0, bucket_max: c_ulonglong = 0, count: c_ulonglong = 0, bucket_bit: c_uint = 0 }
impl Copy for tommy_arrayof_struct

pub type tommy_arrayof = tommy_arrayof_struct

pub type tommy_arrayblk_struct { block: tommy_array_struct, count: c_ulonglong = 0 }
impl Copy for tommy_arrayblk_struct

pub type tommy_arrayblk = tommy_arrayblk_struct

pub type tommy_arrayblkof_struct { block: tommy_array_struct, element_size: c_ulonglong = 0, count: c_ulonglong = 0 }
impl Copy for tommy_arrayblkof_struct

pub type tommy_arrayblkof = tommy_arrayblkof_struct

pub type tommy_list = *mut tommy_node_struct

pub type tommy_tree_node = tommy_node_struct

pub type tommy_tree_struct { root: *mut tommy_node_struct = null, cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, count: c_ulonglong = 0 }
impl Copy for tommy_tree_struct

pub type tommy_tree = tommy_tree_struct

pub type tommy_trie_node = tommy_node_struct

pub type tommy_trie_struct { bucket: [32]*mut tommy_node_struct = [null as *mut tommy_node_struct; 32], count: c_ulonglong = 0, node_count: c_ulonglong = 0, alloc: *mut tommy_allocator_struct = null }
impl Copy for tommy_trie_struct

pub type tommy_trie = tommy_trie_struct

pub type tommy_trie_inplace_node_struct { next: *mut tommy_trie_inplace_node_struct = null, prev: *mut tommy_trie_inplace_node_struct = null, data: *mut c_void = null, map: [4]*mut tommy_trie_inplace_node_struct = [null as *mut tommy_trie_inplace_node_struct; 4], key: c_ulonglong = 0 }
impl Copy for tommy_trie_inplace_node_struct

pub type tommy_trie_inplace_node = tommy_trie_inplace_node_struct

pub type tommy_trie_inplace_struct { bucket: [64]*mut tommy_trie_inplace_node_struct = [null as *mut tommy_trie_inplace_node_struct; 64], count: c_ulonglong = 0 }
impl Copy for tommy_trie_inplace_struct

pub type tommy_trie_inplace = tommy_trie_inplace_struct

pub type tommy_hashtable_node = tommy_node_struct

pub type tommy_hashtable_struct { bucket: *mut *mut tommy_node_struct = null, bucket_max: c_ulonglong = 0, bucket_mask: c_ulonglong = 0, count: c_ulonglong = 0 }
impl Copy for tommy_hashtable_struct

pub type tommy_hashtable = tommy_hashtable_struct

pub type tommy_hashdyn_node = tommy_node_struct

pub type tommy_hashdyn_struct { bucket: *mut *mut tommy_node_struct = null, bucket_max: c_ulonglong = 0, bucket_mask: c_ulonglong = 0, count: c_ulonglong = 0, bucket_bit: c_uint = 0 }
impl Copy for tommy_hashdyn_struct

pub type tommy_hashdyn = tommy_hashdyn_struct

pub type tommy_hashlin_node = tommy_node_struct

pub type tommy_hashlin_struct { bucket: [64]*mut *mut tommy_node_struct = [null as *mut *mut tommy_node_struct; 64], bucket_max: c_ulonglong = 0, bucket_mask: c_ulonglong = 0, low_max: c_ulonglong = 0, low_mask: c_ulonglong = 0, split: c_ulonglong = 0, count: c_ulonglong = 0, bucket_bit: c_uint = 0, state: c_uint = 0 }
impl Copy for tommy_hashlin_struct

pub type tommy_hashlin = tommy_hashlin_struct

pub type object { value: c_int = 0, node: tommy_node_struct, payload: [16]c_char = [0 as c_char; 16] }
impl Copy for object

pub type object_vector { value: c_int = 0, payload: [16]c_char = [0 as c_char; 16] }
impl Copy for object_vector

pub type object_hash { value: c_int = 0, node: tommy_node_struct, payload: [16]c_char = [0 as c_char; 16] }
impl Copy for object_hash

pub type object_tree { value: c_int = 0, node: tommy_node_struct, payload: [16]c_char = [0 as c_char; 16] }
impl Copy for object_tree

pub type object_trie { value: c_int = 0, node: tommy_node_struct, payload: [16]c_char = [0 as c_char; 16] }
impl Copy for object_trie

pub type object_trie_inplace { value: c_int = 0, node: tommy_trie_inplace_node_struct, payload: [16]c_char = [0 as c_char; 16] }
impl Copy for object_trie_inplace

pub type hash32_test { data: *mut i8 = null, len: c_uint = 0, hash: c_uint = 0 }
impl Copy for hash32_test

pub type strhash32_test { data: *mut i8 = null, hash: c_uint = 0 }
impl Copy for strhash32_test

pub type hash64_test { data: *mut i8 = null, len: c_uint = 0, hash: c_ulonglong = 0 }
impl Copy for hash64_test

pub type inthash32_test { value: c_uint = 0, hash: c_uint = 0 }
impl Copy for inthash32_test

pub type inthash64_test { value: c_ulonglong = 0, hash: c_ulonglong = 0 }
impl Copy for inthash64_test

pub var compare_counter: c_uint = 0

pub var SEED: c_ulonglong = 0

pub var HASH32: [24]hash32_test = [hash32_test { data: ("" as *mut c_char), len: 0, hash: 2249472076 }, hash32_test { data: ("a" as *mut c_char), len: 1, hash: 314666038 }, hash32_test { data: ("abc" as *mut c_char), len: 3, hash: 3314453237 }, hash32_test { data: ("message digest" as *mut c_char), len: 14, hash: 7025393 }, hash32_test { data: ("abcdefghijklmnopqrstuvwxyz" as *mut c_char), len: 26, hash: 2121256928 }, hash32_test { data: ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" as *mut c_char), len: 62, hash: 2248453624 }, hash32_test { data: ("The quick brown fox jumps over the lazy dog" as *mut c_char), len: 43, hash: 3736747322 }, hash32_test { data: ("\x00" as *mut c_char), len: 1, hash: 1249713203 }, hash32_test { data: ("\x16\x27" as *mut c_char), len: 2, hash: 2337311131 }, hash32_test { data: ("\xe2\x56\xb4" as *mut c_char), len: 3, hash: 1614832787 }, hash32_test { data: ("\xc9\x4d\x9c\xda" as *mut c_char), len: 4, hash: 2689143882 }, hash32_test { data: ("\x79\xf1\x29\x69\x5d" as *mut c_char), len: 5, hash: 1302512369 }, hash32_test { data: ("\x00\x7e\xdf\x1e\x31\x1c" as *mut c_char), len: 6, hash: 1507733711 }, hash32_test { data: ("\x2a\x4c\xe1\xff\x9e\x6f\x53" as *mut c_char), len: 7, hash: 564008092 }, hash32_test { data: ("\xba\x02\xab\x18\x30\xc5\x0e\x8a" as *mut c_char), len: 8, hash: 621180192 }, hash32_test { data: ("\xec\x4e\x7a\x72\x1e\x71\x2a\xc9\x33" as *mut c_char), len: 9, hash: 2717083864 }, hash32_test { data: ("\xfd\xe2\x9c\x0f\x72\xb7\x08\xea\xd0\x78" as *mut c_char), len: 10, hash: 2153760317 }, hash32_test { data: ("\x65\xc4\x8a\xb8\x80\x86\x9a\x79\x00\xb7\xae" as *mut c_char), len: 11, hash: 2138430735 }, hash32_test { data: ("\x77\xe9\xd7\x80\x0e\x3f\x5c\x43\xc8\xc2\x46\x39" as *mut c_char), len: 12, hash: 3105178498 }, hash32_test { data: ("\x87\xd8\x61\x61\x4c\x89\x17\x4e\xa1\xa4\xef\x13\xa9" as *mut c_char), len: 13, hash: 735905239 }, hash32_test { data: ("\xfe\xa6\x5b\xc2\xda\xe8\x95\xd4\x64\xab\x4c\x39\x58\x29" as *mut c_char), len: 14, hash: 2885675935 }, hash32_test { data: ("\x94\x49\xc0\x78\xa0\x80\xda\xc7\x71\x4e\x17\x37\xa9\x7c\x40" as *mut c_char), len: 15, hash: 2288885940 }, hash32_test { data: ("\x53\x7e\x36\xb4\x2e\xc9\xb9\xcc\x18\x3e\x9a\x5f\xfc\xb7\xb0\x61" as *mut c_char), len: 16, hash: 887958259 }, hash32_test {  }]

pub var STRHASH32: [24]strhash32_test = [strhash32_test { data: ("" as *mut c_char), hash: 183583085 }, strhash32_test { data: ("a" as *mut c_char), hash: 1761218367 }, strhash32_test { data: ("abc" as *mut c_char), hash: 4234739653 }, strhash32_test { data: ("message digest" as *mut c_char), hash: 138902371 }, strhash32_test { data: ("abcdefghijklmnopqrstuvwxyz" as *mut c_char), hash: 1536959973 }, strhash32_test { data: ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" as *mut c_char), hash: 508759271 }, strhash32_test { data: ("The quick brown fox jumps over the lazy dog" as *mut c_char), hash: 2945707774 }, strhash32_test { data: ("\xff" as *mut c_char), hash: 4236804123 }, strhash32_test { data: ("\x16\x27" as *mut c_char), hash: 3446806235 }, strhash32_test { data: ("\xe2\x56\xb4" as *mut c_char), hash: 100240642 }, strhash32_test { data: ("\xc9\x4d\x9c\xda" as *mut c_char), hash: 4132570872 }, strhash32_test { data: ("\x79\xf1\x29\x69\x5d" as *mut c_char), hash: 1925016538 }, strhash32_test { data: ("\xff\x7e\xdf\x1e\x31\x1c" as *mut c_char), hash: 1474279860 }, strhash32_test { data: ("\x2a\x4c\xe1\xff\x9e\x6f\x53" as *mut c_char), hash: 1235220020 }, strhash32_test { data: ("\xba\x02\xab\x18\x30\xc5\x0e\x8a" as *mut c_char), hash: 3902191566 }, strhash32_test { data: ("\xec\x4e\x7a\x72\x1e\x71\x2a\xc9\x33" as *mut c_char), hash: 4265163248 }, strhash32_test { data: ("\xfd\xe2\x9c\x0f\x72\xb7\x08\xea\xd0\x78" as *mut c_char), hash: 1129436290 }, strhash32_test { data: ("\x65\xc4\x8a\xb8\x80\x86\x9a\x79\xff\xb7\xae" as *mut c_char), hash: 2296979765 }, strhash32_test { data: ("\x77\xe9\xd7\x80\x0e\x3f\x5c\x43\xc8\xc2\x46\x39" as *mut c_char), hash: 17865750 }, strhash32_test { data: ("\x87\xd8\x61\x61\x4c\x89\x17\x4e\xa1\xa4\xef\x13\xa9" as *mut c_char), hash: 3165671644 }, strhash32_test { data: ("\xfe\xa6\x5b\xc2\xda\xe8\x95\xd4\x64\xab\x4c\x39\x58\x29" as *mut c_char), hash: 3193839573 }, strhash32_test { data: ("\x94\x49\xc0\x78\xa0\x80\xda\xc7\x71\x4e\x17\x37\xa9\x7c\x40" as *mut c_char), hash: 1893255551 }, strhash32_test { data: ("\x53\x7e\x36\xb4\x2e\xc9\xb9\xcc\x18\x3e\x9a\x5f\xfc\xb7\xb0\x61" as *mut c_char), hash: 2507423913 }, strhash32_test {  }]

pub var HASH64: [24]hash64_test = [hash64_test { data: ("" as *mut c_char), len: 0, hash: ((0 as c_ulonglong) -% 8785335070986182721) }, hash64_test { data: ("a" as *mut c_char), len: 1, hash: 1886448148606962237 }, hash64_test { data: ("abc" as *mut c_char), len: 3, hash: 8454797377981456875 }, hash64_test { data: ("message digest" as *mut c_char), len: 14, hash: ((0 as c_ulonglong) -% 7777253125123395660) }, hash64_test { data: ("abcdefghijklmnopqrstuvwxyz" as *mut c_char), len: 26, hash: 4369609647341344818 }, hash64_test { data: ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" as *mut c_char), len: 62, hash: 7903346942426569293 }, hash64_test { data: ("The quick brown fox jumps over the lazy dog" as *mut c_char), len: 43, hash: ((0 as c_ulonglong) -% 2275007500938993242) }, hash64_test { data: ("\x00" as *mut c_char), len: 1, hash: 2314399751056048161 }, hash64_test { data: ("\x16\x27" as *mut c_char), len: 2, hash: ((0 as c_ulonglong) -% 1206126321667360907) }, hash64_test { data: ("\xe2\x56\xb4" as *mut c_char), len: 3, hash: 7956815500431345260 }, hash64_test { data: ("\xc9\x4d\x9c\xda" as *mut c_char), len: 4, hash: 5878605249808192547 }, hash64_test { data: ("\x79\xf1\x29\x69\x5d" as *mut c_char), len: 5, hash: 2455083796412688321 }, hash64_test { data: ("\x00\x7e\xdf\x1e\x31\x1c" as *mut c_char), len: 6, hash: 1954307946794912091 }, hash64_test { data: ("\x2a\x4c\xe1\xff\x9e\x6f\x53" as *mut c_char), len: 7, hash: 3223163973077387722 }, hash64_test { data: ("\xba\x02\xab\x18\x30\xc5\x0e\x8a" as *mut c_char), len: 8, hash: 5077791314207077773 }, hash64_test { data: ("\xec\x4e\x7a\x72\x1e\x71\x2a\xc9\x33" as *mut c_char), len: 9, hash: 6556689000093852003 }, hash64_test { data: ("\xfd\xe2\x9c\x0f\x72\xb7\x08\xea\xd0\x78" as *mut c_char), len: 10, hash: 1250701583994976950 }, hash64_test { data: ("\x65\xc4\x8a\xb8\x80\x86\x9a\x79\x00\xb7\xae" as *mut c_char), len: 11, hash: ((0 as c_ulonglong) -% 3430778442464937410) }, hash64_test { data: ("\x77\xe9\xd7\x80\x0e\x3f\x5c\x43\xc8\xc2\x46\x39" as *mut c_char), len: 12, hash: 7864867558660569406 }, hash64_test { data: ("\x87\xd8\x61\x61\x4c\x89\x17\x4e\xa1\xa4\xef\x13\xa9" as *mut c_char), len: 13, hash: 2541327869906496569 }, hash64_test { data: ("\xfe\xa6\x5b\xc2\xda\xe8\x95\xd4\x64\xab\x4c\x39\x58\x29" as *mut c_char), len: 14, hash: ((0 as c_ulonglong) -% 7240176141350908567) }, hash64_test { data: ("\x94\x49\xc0\x78\xa0\x80\xda\xc7\x71\x4e\x17\x37\xa9\x7c\x40" as *mut c_char), len: 15, hash: 3897804124304586143 }, hash64_test { data: ("\x53\x7e\x36\xb4\x2e\xc9\xb9\xcc\x18\x3e\x9a\x5f\xfc\xb7\xb0\x61" as *mut c_char), len: 16, hash: 6755293843079777753 }, hash64_test {  }]

pub var INTHASH32: [66]inthash32_test = [inthash32_test {  }, inthash32_test { value: 1, hash: 3266786691 }, inthash32_test { value: 2, hash: 3910079064 }, inthash32_test { value: 4, hash: 2047918803 }, inthash32_test { value: 8, hash: 537670743 }, inthash32_test { value: 16, hash: 3952568586 }, inthash32_test { value: 32, hash: 2142409171 }, inthash32_test { value: 64, hash: 4110811608 }, inthash32_test { value: 128, hash: 1920842477 }, inthash32_test { value: 256, hash: 2130048893 }, inthash32_test { value: 512, hash: 2443477212 }, inthash32_test { value: 1024, hash: 732797644 }, inthash32_test { value: 2048, hash: 4266464526 }, inthash32_test { value: 4096, hash: 3282949238 }, inthash32_test { value: 8192, hash: 596926836 }, inthash32_test { value: 16384, hash: 2558327875 }, inthash32_test { value: 32768, hash: 1661788008 }, inthash32_test { value: 65536, hash: 180594535 }, inthash32_test { value: 131072, hash: 2903010651 }, inthash32_test { value: 262144, hash: 287755487 }, inthash32_test { value: 524288, hash: 1131469764 }, inthash32_test { value: 1048576, hash: 4023838182 }, inthash32_test { value: 2097152, hash: 2593374645 }, inthash32_test { value: 4194304, hash: 269568258 }, inthash32_test { value: 8388608, hash: 2517728864 }, inthash32_test { value: 16777216, hash: 1575788376 }, inthash32_test { value: 33554432, hash: 4276237511 }, inthash32_test { value: 67108864, hash: 907247142 }, inthash32_test { value: 134217728, hash: 1814494284 }, inthash32_test { value: 268435456, hash: 3628988568 }, inthash32_test { value: 536870912, hash: 2962878769 }, inthash32_test { value: 1073741824, hash: 1630659170 }, inthash32_test { value: 2147483648, hash: 3261318340 }, inthash32_test { value: 2116118, hash: 3636032609 }, inthash32_test { value: 89401895, hash: 1708131706 }, inthash32_test { value: 379337186, hash: 2083517850 }, inthash32_test { value: 782977366, hash: 2830797245 }, inthash32_test { value: 196130996, hash: 3079719134 }, inthash32_test { value: 198207689, hash: 2463302982 }, inthash32_test { value: 1046291021, hash: 3591421725 }, inthash32_test { value: 1131187612, hash: 665882649 }, inthash32_test { value: 975888346, hash: 3755905925 }, inthash32_test { value: 500746873, hash: 3351317883 }, inthash32_test { value: 1785185521, hash: 4180310157 }, inthash32_test { value: 2000878121, hash: 2301375769 }, inthash32_test { value: 1219898729, hash: 2137272149 }, inthash32_test { value: 1194203485, hash: 3928771045 }, inthash32_test { value: 109160704, hash: 1306904873 }, inthash32_test { value: 1647229822, hash: 900195078 }, inthash32_test { value: 40619231, hash: 2816783920 }, inthash32_test { value: 541938462, hash: 1139529316 }, inthash32_test { value: 640373553, hash: 2056918559 }, inthash32_test { value: 1881154588, hash: 3136110327 }, inthash32_test { value: 1141509674, hash: 193747753 }, inthash32_test { value: 1976245324, hash: 425022484 }, inthash32_test { value: 1106879969, hash: 3333209195 }, inthash32_test { value: 1740383999, hash: 1424245023 }, inthash32_test { value: 404629406, hash: 2543616847 }, inthash32_test { value: 1903345775, hash: 3869342207 }, inthash32_test { value: 1225384275, hash: 428760591 }, inthash32_test { value: 164872122, hash: 278556439 }, inthash32_test { value: 1750787330, hash: 4191517259 }, inthash32_test { value: 2115037355, hash: 158751724 }, inthash32_test { value: 254158360, hash: 3781428429 }, inthash32_test { value: 1919648304, hash: 1441036468 }, inthash32_test {  }]

pub var INTHASH64: [98]inthash64_test = [inthash64_test { value: 0, hash: 8633297058295171728 }, inthash64_test { value: 1, hash: 6614235796240398542 }, inthash64_test { value: 2, hash: ((0 as c_ulonglong) -% 5218261022256003468) }, inthash64_test { value: 4, hash: 8010255721068513841 }, inthash64_test { value: 8, hash: ((0 as c_ulonglong) -% 2426244500714651957) }, inthash64_test { value: 16, hash: ((0 as c_ulonglong) -% 4852489044378976894) }, inthash64_test { value: 32, hash: 8741766010721401616 }, inthash64_test { value: 64, hash: ((0 as c_ulonglong) -% 963212052266748384) }, inthash64_test { value: 128, hash: ((0 as c_ulonglong) -% 1926422221190336595) }, inthash64_test { value: 256, hash: ((0 as c_ulonglong) -% 3852844468150476978) }, inthash64_test { value: 512, hash: ((0 as c_ulonglong) -% 7705688936300953956) }, inthash64_test { value: 1024, hash: 3035366123798232340 }, inthash64_test { value: 2048, hash: 6070732247596464680 }, inthash64_test { value: 4096, hash: ((0 as c_ulonglong) -% 6305279587106556852) }, inthash64_test { value: 8192, hash: 5836184899496437912 }, inthash64_test { value: 16384, hash: ((0 as c_ulonglong) -% 6774374281159126739) }, inthash64_test { value: 32768, hash: 4897996243683222447 }, inthash64_test { value: 65536, hash: ((0 as c_ulonglong) -% 8650751541245950093) }, inthash64_test { value: 131072, hash: 1145241034167324410 }, inthash64_test { value: 262144, hash: 2290482070482132469 }, inthash64_test { value: 524288, hash: 4580964143111748587 }, inthash64_test { value: 1048576, hash: 9161928288370980823 }, inthash64_test { value: 2097152, hash: ((0 as c_ulonglong) -% 122887494820106321) }, inthash64_test { value: 4194304, hash: ((0 as c_ulonglong) -% 245774987492728993) }, inthash64_test { value: 8388608, hash: ((0 as c_ulonglong) -% 491549972837974337) }, inthash64_test { value: 16777216, hash: ((0 as c_ulonglong) -% 983128386949396030) }, inthash64_test { value: 33554432, hash: ((0 as c_ulonglong) -% 1966256773898792060) }, inthash64_test { value: 67108864, hash: ((0 as c_ulonglong) -% 3932513545650100471) }, inthash64_test { value: 134217728, hash: ((0 as c_ulonglong) -% 7865027091300200942) }, inthash64_test { value: 268435456, hash: 2716689891109149732 }, inthash64_test { value: 536870912, hash: 5433379782218299464 }, inthash64_test { value: 1073741824, hash: ((0 as c_ulonglong) -% 7579984532895272827) }, inthash64_test { value: 2147483648, hash: 3286775078785966347 }, inthash64_test { value: 4294967296, hash: 6573550159719416343 }, inthash64_test { value: 8589934592, hash: ((0 as c_ulonglong) -% 5299643820842712017) }, inthash64_test { value: 17179869184, hash: 7847456434171611231 }, inthash64_test { value: 34359738368, hash: ((0 as c_ulonglong) -% 2557050633072013142) }, inthash64_test { value: 68719476736, hash: ((0 as c_ulonglong) -% 5114101334863503020) }, inthash64_test { value: 137438953472, hash: 8218541403982545576 }, inthash64_test { value: 274877906944, hash: ((0 as c_ulonglong) -% 2009661358086257339) }, inthash64_test { value: 549755813888, hash: ((0 as c_ulonglong) -% 4019322647453037942) }, inthash64_test { value: 1099511627776, hash: ((0 as c_ulonglong) -% 7825850141557779179) }, inthash64_test { value: 2199023255552, hash: 2795043861460953643 }, inthash64_test { value: 4398046511104, hash: 5590087722921907286 }, inthash64_test { value: 8796093022208, hash: ((0 as c_ulonglong) -% 7266568627865737044) }, inthash64_test { value: 17592186044416, hash: ((0 as c_ulonglong) -% 5871544257108697912) }, inthash64_test { value: 35184372088832, hash: 4997081253158044244 }, inthash64_test { value: 70368744177664, hash: ((0 as c_ulonglong) -% 6713905380557802641) }, inthash64_test { value: 140737488355328, hash: 8903327622686910532 }, inthash64_test { value: 281474976710656, hash: ((0 as c_ulonglong) -% 2881700622017090057) }, inthash64_test { value: 562949953421312, hash: 3182232149757329758 }, inthash64_test { value: 1125899906842624, hash: ((0 as c_ulonglong) -% 7807866675693632779) }, inthash64_test { value: 2251799813685248, hash: 8040351638658041266 }, inthash64_test { value: 4503599627370496, hash: 7135320778318102740 }, inthash64_test { value: 9007199254740992, hash: 7077370701054130027 }, inthash64_test { value: 18014398509481984, hash: 300551503041479582 }, inthash64_test { value: 36028797018963968, hash: 8233019949818890027 }, inthash64_test { value: 72057594037927936, hash: 7649797498114617030 }, inthash64_test { value: 144115188075855872, hash: 8689487284176655099 }, inthash64_test { value: 288230376151711744, hash: 8741180464548767206 }, inthash64_test { value: 576460752303423488, hash: 8382365354043305020 }, inthash64_test { value: 1152921504606846976, hash: 8245571742153706983 }, inthash64_test { value: 2305843009213693952, hash: 7536964969603551550 }, inthash64_test { value: 4611686018427387904, hash: 6474972759361640428 }, inthash64_test { value: ((0 as c_ulonglong) -% ((9223372036854775807 as c_ulonglong) +% (1 as c_ulonglong))), hash: 4316648529147585864 }, inthash64_test { value: 930788331773097413, hash: 1097585172816924377 }, inthash64_test { value: 183007028018183050, hash: ((0 as c_ulonglong) -% 6215528967931877006) }, inthash64_test { value: 6261538925075934286, hash: 3496009142145320643 }, inthash64_test { value: 6942493569461025906, hash: 8037586316725169092 }, inthash64_test { value: 5759135434064797809, hash: 1293071192093771172 }, inthash64_test { value: 5695891564148026313, hash: 6990333691147561679 }, inthash64_test { value: 1720489279671355133, hash: 6375102204810644860 }, inthash64_test { value: 4699311663094207388, hash: 6184635464318236639 }, inthash64_test { value: 6472063777816752242, hash: ((0 as c_ulonglong) -% 7426843614004052192) }, inthash64_test { value: 8082554962057490440, hash: 1927432582143697729 }, inthash64_test { value: 4844598281755214032, hash: ((0 as c_ulonglong) -% 3228139061431427222) }, inthash64_test { value: 5005922252856969317, hash: ((0 as c_ulonglong) -% 6524657794574135539) }, inthash64_test { value: 1578504764520419978, hash: 7879415617040044511 }, inthash64_test { value: 7949674155292948608, hash: 6749877675382105343 }, inthash64_test { value: 484959915982837402, hash: 1816117011025244485 }, inthash64_test { value: 3083224906385443840, hash: 4950044616489513297 }, inthash64_test { value: 2493212396492039086, hash: 4631130514840771685 }, inthash64_test { value: 6237081787206561257, hash: 617130085943212889 }, inthash64_test { value: 4281592898429077120, hash: ((0 as c_ulonglong) -% 254468864356974002) }, inthash64_test { value: 4724239022075612735, hash: 3344535755785323538 }, inthash64_test { value: 6813844841883157827, hash: ((0 as c_ulonglong) -% 6254022038912321006) }, inthash64_test { value: 5330807607442767810, hash: ((0 as c_ulonglong) -% 1721805229525686710) }, inthash64_test { value: 3076264791618840633, hash: ((0 as c_ulonglong) -% 5653707719277195922) }, inthash64_test { value: 1631870286633119704, hash: ((0 as c_ulonglong) -% 6357799844674044617) }, inthash64_test { value: 7864592595372063073, hash: 8076697783213863138 }, inthash64_test { value: 8807280653546846857, hash: 7768865109220875130 }, inthash64_test { value: 1281267090837179726, hash: 4977481139259887757 }, inthash64_test { value: 1171252490924260516, hash: 5313413296334299200 }, inthash64_test { value: 4637366392588051, hash: ((0 as c_ulonglong) -% 9103134190710974926) }, inthash64_test { value: 5412091614408648190, hash: 1525794091612659609 }, inthash64_test { value: 247056698743630171, hash: 622169565100867497 }, inthash64_test { value: 7243511033451343322, hash: ((0 as c_ulonglong) -% 3223268276556731764) }, inthash64_test {  }]

pub let TOMMY_SIZE_BIT: c_int = 64
pub fn tommy_cast[T](type_: T, value: T) -> T {
    value
}
pub fn tommy_likely[T](x: T) -> T {
    (if (if x != 0: 0 else: 1) != 0: 0 else: 1)
}
pub fn tommy_unlikely[T](x: T) -> T {
    (if (if x != 0: 0 else: 1) != 0: 0 else: 1)
}
pub fn TOMMY_ILOG2[T](value: T) -> T {
    (if (value == 256): 8 else: (if (value == 128): 7 else: (if (value == 64): 6 else: (if (value == 32): 5 else: (if (value == 16): 4 else: (if (value == 8): 3 else: (if (value == 4): 2 else: (if (value == 2): 1 else: 0))))))))
}
pub let TOMMY_ARRAY_BIT: c_int = 6
pub let TOMMY_ARRAYOF_BIT: c_int = 6
pub let TOMMY_ARRAYBLK_SIZE: c_int = 4096
pub let TOMMY_ARRAYBLKOF_SIZE: c_int = 4096
pub let TOMMY_TRIE_BIT: c_int = 32
pub let TOMMY_TRIE_TREE_MAX: c_ulong = 8
pub let TOMMY_TRIE_BLOCK_SIZE: c_ulong = 64
pub let TOMMY_TRIE_TREE_BIT: c_int = 3
pub let TOMMY_TRIE_BUCKET_BIT: c_int = 5
pub let TOMMY_TRIE_BUCKET_MAX: c_int = 32
pub let TOMMY_TRIE_INPLACE_BIT: c_int = 32
pub let TOMMY_TRIE_INPLACE_TREE_MAX: c_int = 4
pub let TOMMY_TRIE_INPLACE_TREE_BIT: c_int = 2
pub let TOMMY_TRIE_INPLACE_BUCKET_BIT: c_int = 6
pub let TOMMY_TRIE_INPLACE_BUCKET_MAX: c_int = 64
pub let TOMMY_HASHDYN_BIT: c_int = 4
pub let TOMMY_HASHLIN_BIT: c_int = 6
pub let TOMMY_SIZE: c_int = 1000000
pub let PAYLOAD: c_int = 16
pub fn START[T](s: T) -> T {
    unsafe { start(s) }
}
pub let TOMMY_ALLOCATOR_BLOCK_SIZE: c_int = 4032
pub fn tommy_swap32[T](x: T) -> T {
    with_bswap32(x)
}
pub let TOMMY_HASHLIN_STATE_STABLE: c_int = 0
pub let TOMMY_HASHLIN_STATE_GROW: c_int = 1
pub let TOMMY_HASHLIN_STATE_SHRINK: c_int = 2
pub type tommy_chain_struct { head: *mut tommy_node_struct = null, tail: *mut tommy_node_struct = null }
impl Copy for tommy_chain_struct

pub type tommy_chain = tommy_chain_struct

pub type tommy_trie_tree_struct { map: [8]*mut tommy_node_struct = [null as *mut tommy_node_struct; 8] }
impl Copy for tommy_trie_tree_struct

pub type tommy_trie_tree = tommy_trie_tree_struct

pub let TOMMY_TRIE_TREE_MASK: c_ulong = 7
pub let TOMMY_TRIE_BUCKET_SHIFT: c_int = 27
pub let TOMMY_TRIE_LEVEL_MAX: c_int = 9
pub let TOMMY_TRIE_TYPE_NODE: c_int = 0
pub let TOMMY_TRIE_TYPE_TREE: c_int = 1
pub fn trie_get_type[T](ptr: T) -> T {
    ((ptr as c_ulong) & 1)
}
pub let TOMMY_TRIE_INPLACE_TREE_MASK: c_int = 3
pub let TOMMY_TRIE_INPLACE_BUCKET_SHIFT: c_int = 26
