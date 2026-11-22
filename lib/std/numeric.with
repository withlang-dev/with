// std.numeric: the members of the numeric types (§4.1a, D203). `i32.max`
// in a program is the function here that states it: the parser reads a
// numeric type's `min`, `max`, `inf` or `nan` as a call of `__<type>_<member>`.
// Each is one constant, stated once.

pub comptime fn __i8_min() -> i8: -128
pub comptime fn __i8_max() -> i8: 127
pub comptime fn __i16_min() -> i16: -32768
pub comptime fn __i16_max() -> i16: 32767
pub comptime fn __i32_min() -> i32: -2147483648
pub comptime fn __i32_max() -> i32: 2147483647
pub comptime fn __i64_min() -> i64: -9223372036854775808
pub comptime fn __i64_max() -> i64: 9223372036854775807
pub comptime fn __i128_min() -> i128: -170141183460469231731687303715884105728
pub comptime fn __i128_max() -> i128: 170141183460469231731687303715884105727
pub comptime fn __u8_min() -> u8: 0
pub comptime fn __u8_max() -> u8: 255
pub comptime fn __u16_min() -> u16: 0
pub comptime fn __u16_max() -> u16: 65535
pub comptime fn __u32_min() -> u32: 0
pub comptime fn __u32_max() -> u32: 4294967295
pub comptime fn __u64_min() -> u64: 0
pub comptime fn __u64_max() -> u64: 18446744073709551615
pub comptime fn __u128_min() -> u128: 0
pub comptime fn __u128_max() -> u128: 340282366920938463463374607431768211455

// The size integers have the target's width (D114): their limits are
// computed from it, never written for one width.
fn size_top_bit() -> usize: (1 as usize) << (sizeof[usize]() as u32 * 8 - 1)
pub comptime fn __usize_min() -> usize: 0
pub comptime fn __usize_max() -> usize: size_top_bit() - 1 + size_top_bit()
pub comptime fn __isize_min() -> isize: -((size_top_bit() - 1) as isize) - 1
pub comptime fn __isize_max() -> isize: (size_top_bit() - 1) as isize

// A floating-point type's `min` and `max` are its finite extremes: `min` is
// the most negative finite value, not the smallest positive one.
pub comptime fn __f32_min() -> f32: -3.4028235e38
pub comptime fn __f32_max() -> f32: 3.4028235e38
pub comptime fn __f64_min() -> f64: -1.7976931348623157e308
pub comptime fn __f64_max() -> f64: 1.7976931348623157e308
pub comptime fn __f32_inf() -> f32: (1.0 / 0.0) as f32
pub comptime fn __f32_nan() -> f32: (0.0 / 0.0) as f32
pub comptime fn __f64_inf() -> f64: 1.0 / 0.0
pub comptime fn __f64_nan() -> f64: 0.0 / 0.0
