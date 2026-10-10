//! expect-stdout: 1 0
//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 4
//! expect-stdout: 5 7

// A type parameter no argument mentions takes its type from the result the
// call is checked against: the annotated binding, a parameter, a return, a
// field. The uninferable-parameter diagnostic teaches exactly this
// restructure ("annotate the result binding"); generic calls never bound
// it, so `var xs: ArenaList[i32] = arena_vec_new_in(arena)` was refused.
type Slot[T] { n: i32, items: List[T] }

fn empty[T](n: i32) -> Slot[T]: Slot { n: n, items: List.new() }
fn paired[T, U](first: T) -> (T, List[U]): (first, List.new())

fn count(s: Slot[str]): s.n
fn made() -> Slot[f64]: empty(3)

type Holder { slot: Slot[bool] }

fn main:
    var a: Slot[i64] = empty(1)
    a.items.push(9)
    print(f"{a.n} {a.items.len() - 1}")
    print(count(empty(2)))
    print(made().n)
    let h = Holder { slot: empty(4) }
    print(h.slot.n)
    let (first, rest): (i32, List[str]) = paired(5i32)
    print(f"{first} {rest.len() + 7}")
