//! expect-stdout: 4294967295 4294967295 4294967295 14 -2147483648 true true

// #3441 (§4.1a): a numeric type's `min` and `max` are the type's, however
// it is named: a C integer type (whose width is the target's, so a program
// cannot know which builtin to spell), a program's own alias, in a
// constant and as a call argument. The parser knew only the builtin
// spellings; the rest was "unknown field 'max' for type 'u32'".
type uInt = c_uint
type Meters = f64

const TOP: u32 = uInt.max

fn cap(n: u32) -> u32: if n > c_uint.max / 2: c_uint.max else: n * 2

fn main:
    let big: f64 = Meters.max
    print(f"{u32.max} {c_uint.max} {TOP} {cap(7)} {c_int.min} {big > 1.0e300} {Meters.inf > big}")
