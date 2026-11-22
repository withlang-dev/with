//! expect-stdout: isize f64 P
//! expect-stdout: isize f64 P
//! expect-stdout: 8 8 16
//! expect-stdout: 8 8 8
//! expect-stdout: P 16 8 P
// #3332 (§17.2): `T.name()`, `T.size()` and `T.align()` on a type parameter,
// and `nameof[T]()`, are each instance's own type. `T.name()` and `T.size()`
// aborted the compiler (a method call with no signature reached MIR), and
// `nameof[T]()` printed `T` in every instance: the name was read from the
// syntax.
type P { x: i32, y: i64 }

fn who[T](x: T) -> str: T.name()
fn named[T](x: T) -> str: nameof[T]()
fn big[T](x: T) -> usize: T.size()
fn edge[T](x: T) -> usize: T.align()

fn main:
    let of_p_who = who(P { x: 1, y: 2 })
    print(f"{who(1)} {who(2.5)} {of_p_who}")
    let of_p_named = named(P { x: 1, y: 2 })
    print(f"{named(1)} {named(2.5)} {of_p_named}")
    let of_p_big = big(P { x: 1, y: 2 })
    print(f"{big(1)} {big(2.5)} {of_p_big}")
    let of_p_edge = edge(P { x: 1, y: 2 })
    print(f"{edge(1)} {edge(2.5)} {of_p_edge}")
    print(f"{P.name()} {P.size()} {P.align()} {nameof[P]()}")
