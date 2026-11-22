// #3401: a small package whose `pub` functions leave facts to inference.
// `with build :package-interface-check` builds its bundle and checks every
// program in ../app against the interface alone and against this source:
// the two must accept and refuse the same programs.

pub type Shape { w: i32, h: i32, name: str }

pub fn area(s: &Shape): s.w * s.h

pub fn label(s: &Shape) -> &str: s.name

pub fn bigger(a: &Shape, b: &Shape) -> &Shape: if area(a) > area(b): a else: b

pub fn each(xs: &List[Shape], body: fn(&Shape) -> i32) -> i32:
    var t = 0
    for x in xs: t += body(x)
    for x in xs: t += body(x)
    t

fn private_helper(s: &Shape) -> i32: s.w

pub fn first_of[T](xs: &List[T]) -> &T: xs[0]

pub fn apply(s: &Shape, body: fn(&Shape) -> i32) -> i32: body(s)

pub type Keeper { held: List[fn() -> i32] }

pub fn keep(mut k: Keeper, f: fn() -> i32):
    k.held.push(f)

pub fn run_now(f: fn() -> i32) -> i32: f()

pub fn later(f: fn() -> i32) -> fn() -> i32: move () => f() + 1

impl Keeper:
    /// A method that returns a closure holding its callable parameter.
    pub fn wrapped(f: fn() -> i32) -> fn() -> i32: move () => f() + 1

/// A generic function is the importer's to instantiate: the interface
/// carries it as source. Its body calls a private function of the package,
/// which the bundle's object provides.
pub fn widest[T](xs: &List[T], width: fn(&T) -> i32) -> i32:
    var best = 0
    for x in xs:
        let w = clamp_width(width(x))
        if w > best: best = w
    best

fn clamp_width(w: i32) -> i32: if w < 0: 0 else: w

/// A generic type and its methods are the importer's to instantiate: the
/// interface carries both as the source wrote them.
pub type Pair[T] { a: T, b: T }

impl[T] Pair[T]:
    pub fn first() -> &T: self.a
    pub fn swapped() -> Pair[T]: Pair { a: self.b, b: self.a }

pub type Tally { n: i32 }

impl Tally:
    /// A generic method of a type that is not generic.
    pub fn plus_count[T](xs: &List[T]) -> i32: self.n + xs.len32()

/// A `comptime` function is evaluated by whoever calls it: the interface
/// carries it as the source wrote it.
pub comptime fn squared(n: i32) -> i32: n * n
