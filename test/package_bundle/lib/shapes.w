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
