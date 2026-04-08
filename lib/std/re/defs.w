// std.re.defs -- shared C type aliases for migrated PCRE2 code.

use std.mem
use std.string

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

