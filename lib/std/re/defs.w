// std.re.defs — shared type aliases for migrated PCRE2

fn is_alpha(c: i32) -> bool: (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
fn is_digit(c: i32) -> bool: c >= 48 and c <= 57
fn is_space(c: i32) -> bool: c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11
fn is_alnum(c: i32) -> bool: is_alpha(c) or is_digit(c)
fn is_upper(c: i32) -> bool: c >= 65 and c <= 90
fn is_lower(c: i32) -> bool: c >= 97 and c <= 122
fn is_xdigit(c: i32) -> bool: (c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)
fn is_print(c: i32) -> bool: c >= 32 and c <= 126
fn to_lower(c: i32) -> i32: if c >= 65 and c <= 90: c + 32 else: c
fn to_upper(c: i32) -> i32: if c >= 97 and c <= 122: c - 32 else: c
extern fn strlen(s: *const i8) -> i64
extern fn strcmp(a: *const i8, b: *const i8) -> i32
extern fn strncmp(a: *const i8, b: *const i8, n: i64) -> i32
extern fn memchr(s: *const i8, c: i32, n: i64) -> *i8
fn string_len(s: *const i8) -> i64: strlen(s)
fn string_cmp(a: *const i8, b: *const i8) -> i32: strcmp(a, b)

type c_void = opaque
type c_char = i8
type c_short = i16
type c_ushort = u16
type c_int = i32
type c_uint = u32
type c_long = i64
type c_ulong = u64
type c_longlong = i64
type c_ulonglong = u64
type c_longdouble = f64
extern fn with_clz(x: i32) -> i32
extern fn with_ctz(x: i32) -> i32
extern fn with_popcount(x: i32) -> i32
extern fn with_bswap16(x: u16) -> u16
extern fn with_bswap32(x: u32) -> u32
extern fn with_bswap64(x: u64) -> u64
extern fn with_clzl(x: i64) -> i32
extern fn with_clzll(x: i64) -> i32
extern fn with_ctzl(x: i64) -> i32
extern fn with_ctzll(x: i64) -> i32
extern fn with_abs(x: i32) -> i32
extern fn with_alloc(size: i64) -> *i8
extern fn with_free(ptr: *i8) -> void
extern fn with_memcpy(dst: *i8, src: *i8, n: i64) -> void
extern fn with_memmove(dst: *i8, src: *i8, n: i64) -> void
extern fn with_memset(ptr: *i8, c: i32, n: i64) -> void
extern fn with_memcmp(a: *i8, b: *i8, n: i64) -> i32

