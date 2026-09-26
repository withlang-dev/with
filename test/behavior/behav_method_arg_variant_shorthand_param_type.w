//! expect-stdout: 2 2 2 2 2
//! expect-stdout: 12 1
//! expect-stdout: 20 3 5
//! expect-stdout: ok

// §4 / #1712: `.Variant` in a method argument resolves against the
// parameter's declared type, as it does for a free function's argument, a
// typed `let`, a match arm and a return. Two enums here share `Boss` and
// `Cleared`; the later-declared `BannerKind` won by name, so every method
// call below was "wrong argument type ... has type BannerKind". Each call
// answers `Kind`'s ordinal, which no `BannerKind` value can produce.

pub enum Kind { | Block | Boss | Cleared }
impl Copy for Kind
pub enum BannerKind { | Boss | Cleared }
impl Copy for BannerKind

fn ord(k: Kind) -> i32:
    match k:
        .Block => 1
        .Boss => 2
        .Cleared => 3

fn banner(b: BannerKind) -> i32:
    match b:
        .Boss => 10
        .Cleared => 20

pub type G { n: i32 = 0 }
extend G:
    fn place(mut self: Self, x: i32, kind: Kind, elite: bool = false) -> i32:
        self.n += x
        ord(kind) + (if elite: 100 else: 0)
    fn look(self: &Self, kind: Kind) -> i32: ord(kind)
    fn relay(mut self: Self) -> i32: self.place(1, .Boss)
    fn show(self: &Self, b: BannerKind, k: Kind) -> i32: banner(b) + ord(k) - 10
    // A `&T` parameter meets its argument through auto-ref (§3.8): an owned
    // join with a literal arm still passes (the compiler's own source).
    fn label(self: &Self, s: &str) -> i32: s.len() as i32

fn G.make(kind: Kind) -> i32: ord(kind)

// A generic owner: the parameter type is substituted for the receiver.
type Slot[T] { v: T }
extend Slot[T]:
    fn tag(self: &Self, kind: Kind) -> i32: ord(kind) * 10
    fn put(mut self: Self, v: T, kind: Kind) -> i32:
        self.v = v
        ord(kind)

fn main:
    var g = G {}
    let a = g.place(1, .Boss)
    let b = g.look(.Boss)
    let c = G.make(.Boss)
    let d = g.relay()
    let e = g.place(1, .Boss, elite: false)
    print(f"{a} {b} {c} {d} {e}")
    print(f"{g.show(.Cleared, .Block) + 1} {g.look(.Block)}")
    assert(g.n == 3)
    let long = g.n > 2
    let who = "ab".clone()
    assert(g.label(if long: who ++ "(...)" else: "the generator") == 7)
    assert(g.label(if g.n > 9: who ++ "(...)" else: "the generator") == 13)
    var s = Slot { v: 1 }
    let p = s.put(5, .Cleared)
    print(f"{s.tag(.Boss)} {p} {s.v}")
    print("ok")
