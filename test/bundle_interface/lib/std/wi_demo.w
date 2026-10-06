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
// with `fn`, `mut fn` and `move fn` methods. Layout attributes cover both
// an unused type and a demanded packed type in the on-demand consumer.
pub type Pair { pub a: i32, pub b: i32 }
@[repr(packed)]
pub type Packet { pub tag: u8, pub word: i32 }
pub type Word = i32
pub type VarArgs = c_va_list
pub type Handle = distinct i32
pub type Bits = union { whole: u32, half: u16 }
impl Copy for Bits
@[repr(C)]
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
// §21.1 rule 1: an exported function's writes of exported globals are its
// declared, checked contract (`writes`, the declaration's last clause); the
// `.wi` prints it as written. `reserve` declares a write its body does not
// make: a conservative contract, linted, not refused.
pub fn bump() writes COUNTER: COUNTER = COUNTER + 1
pub fn reserve() -> i32 writes COUNTER: 0
pub fn take(p: Pair) -> i32: p.a * p.b
// §21.1 rule 6 (#1903): a returned view of a global states the global as
// its origin; the private LEVEL crosses as a declaration without `pub` (an
// identity a consumer cannot name), and `raise`, which writes it, declares
// the write though LEVEL is not exported.
var LEVEL: i32 = 3
// §21.1 rule 6 (spec v7.18): `from static` states a view of static data;
// the interface carries it, and a consumer's view is tied to nothing.
pub fn greeting() -> &str from static: "hello"
pub fn level() -> &i32 from LEVEL: &LEVEL
pub fn raise() writes LEVEL: LEVEL = LEVEL + 1
pub fn table_at(i: i64) -> u8: TABLE[i]
pub unsafe fn set_first(p: *mut Pair, v: i32) -> Unit: (*p).a = v
pub fn sum_slice(xs: []i32) -> i32:
    var total = 0
    for x in xs: total = total + x
    total
pub fn level_value(l: Level) -> u8: l as u8
pub fn packet_word(p: &Packet) -> i32: p.word
pub fn va_size(args: &c_va_list) -> i64: sizeof[c_va_list]()
// §12.4 (D75): a consuming closure crosses the boundary only to `once`.
pub fn call_once(f: once fn() -> i32) -> i32: f()
pub fn call_twice(f: fn() -> i32) -> i32: f() + f()
impl Pair:
    pub fn sum() -> i32: self.a + self.b
    pub mut fn scale(k: i32) -> Unit:
        self.a = self.a * k
        self.b = self.b * k
    pub move fn into_word() -> Word: self.a + self.b
