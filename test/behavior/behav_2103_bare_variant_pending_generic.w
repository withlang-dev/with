//! expect-stdout: 5
//! expect-stdout: 5 -1
//! expect-stdout: full 3
//! expect-stdout: true 7

// #2103: a bare variant of a generic enum (`var best = None`) is a pending
// generic binding, as `Vec.new()` is: what is assigned to it, the type its
// use demands, or the place it is passed to settles its type arguments.
// Sema said ok and codegen failed ("aggregate enum payload missing
// destination payload type").

type Pick { score: i32 = 0 }

fn best_of(xs: &Vec[i32]) -> Option[Pick]:
    var best = None
    for x in xs:
        if x > 2: best = Some(Pick { score: x })
    best

enum Slot[T] { Empty, Full(T) }
type Pair[T] { a: Option[T], b: T }

fn takes(o: Option[i32]) -> i32: o ?? -1

fn only_assigned(xs: &Vec[i32]) -> i32:
    var best = None
    for x in xs:
        if x > 2: best = Some(x)
    match best:
        Some(v) => v
        None => 0

fn passed() -> i32:
    let nothing = None
    takes(nothing)

fn user_enum(n: i32) -> Slot[i32]:
    var s = Empty
    if n > 0: s = Full(n)
    s

fn main:
    var xs = Vec.new()
    xs.push(1)
    xs.push(5)
    match best_of(&xs):
        Some(p) => print(f"{p.score}")
        None => print("none")
    print(f"{only_assigned(&xs)} {passed()}")
    match user_enum(3):
        Full(v) => print(f"full {v}")
        Empty => print("empty")
    let p = Pair { a: None, b: 7 }
    print(f"{p.a.is_none()} {p.b}")
