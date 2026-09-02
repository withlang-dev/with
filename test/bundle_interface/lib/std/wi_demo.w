// D39 bundle-interface demo module (build/selfhost.w bs_check_bundle_interface).
// Lives under lib/std/ so its canonical path is <embedded-std>/std/wi_demo.w
// in both the bundle object and the consumer; wi_demo.wi is its interface,
// hand-written, and the emitter (`--emit-bundle-interface`) must regenerate
// it byte for byte from this source. Every declaration shape the emitter
// prints is here: struct, union, alias, distinct, plain enum with a payload
// variant, discriminant enum with explicit values, Copy impls, const (int
// and an escaped string), storage `let` and `var`, free fns with `&T`,
// `*mut T` (a `&mut T` parameter is not safe With, §15.1), `[]T` and
// consuming parameters, an `extern "C" fn` pointer field, and an impl block
// with `fn`, `mut fn` and `move fn` methods.
pub type Pair { a: i32, b: i32 }
pub type Word = i32
pub type Handle = distinct i32
pub type Bits = union { whole: u32, half: u16 }
impl Copy for Bits
pub type Callback { call: extern "C" fn(i32) -> i32, tag: u8 }
impl Copy for Callback
pub enum Color:
    Red
    Green
    Mixed(i32, i32)
pub enum Level: u8:
    Low = 1
    High = 200
impl Copy for Level
pub const K: i32 = 7
pub const GREETING: str = "hi\n"
pub let TABLE: [4]u8 = [1, 2, 3, 4]
pub var COUNTER: i32 = 0
pub fn add(p: &Pair) -> i32: p.a + p.b
pub fn take(p: Pair) -> i32: p.a * p.b
pub fn table_at(i: i64) -> u8: TABLE[i]
pub unsafe fn set_first(p: *mut Pair, v: i32) -> Unit: (*p).a = v
pub fn sum_slice(xs: []i32) -> i32:
    var total = 0
    for x in xs: total = total + x
    total
pub fn level_value(l: Level) -> u8: l as u8
impl Pair:
    pub fn sum() -> i32: self.a + self.b
    pub mut fn scale(k: i32) -> Unit:
        self.a = self.a * k
        self.b = self.b * k
    pub move fn into_word() -> Word: self.a + self.b
