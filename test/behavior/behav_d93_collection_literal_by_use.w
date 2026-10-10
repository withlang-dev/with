//! expect-stdout: 6
//! expect-stdout: 3 4
//! expect-stdout: 2
//! expect-stdout: 3000000000
//! expect-stdout: 9
//! expect-stdout: 3
//! expect-stdout: 6 3
//! expect-stdout: 2 1
//! expect-stdout: 3

// D93 (§4.3c rule 1): a binding with no annotation whose initializer is an
// element-form literal takes its type from its uses in its own function — a
// parameter, a typed place, a return, or a method exactly one collection
// has — and the demand settles the element type too. A slice demand views
// the List, and with no demand the literal is a List (D113).
use std.collections.HashSet

fn total(xs: &List[i32]): xs.iter() |> sum()

fn archive(xs: List[i32]): xs.len()

fn distinct(names: &HashSet[str]): names.len()

fn widest(xs: &List[i64]): (xs.iter() |> max()) ?? 0

fn first_two(xs: []i32): xs[0] + xs[1]

fn made() -> List[i32]:
    let xs = [1, 2, 3]
    xs

fn main:
    // A parameter that views a List, then one that takes it.
    let xs = [1, 2, 3]
    print(total(xs))
    // A method only a List has.
    var grown = [1, 2, 3]
    grown.push(4)
    print(f"{archive(xs)} {grown.len()}")
    // Another collection, by its parameter.
    let names = ["a", "b"]
    print(distinct(names))
    // The demand settles the element type.
    let wide = [1, 3000000000]
    print(widest(wide))
    // A slice demand views the List; nothing is demanded.
    let pair: List[i32] = [4, 5]
    print(first_two(pair))
    // A typed place.
    let ys = [7, 8, 9]
    let kept: List[i32] = ys
    print(kept.len())
    // A return (in `made`), and no demand at all: a List.
    let plain = [1, 2, 3]
    print(f"{total(made())} {plain.len()}")
    // The empty literal takes its element type from the method's argument.
    var later = []
    later.push("x")
    later.push("y")
    print(f"{later.len()} {later[0].len()}")
    print(assigned([9, 8]).len())

// Assignment is a demand in both directions: into the binding, and from
// the binding to a typed place.
fn assigned(replacement: List[i32]) -> List[i32]:
    var xs = [1, 2, 3]
    xs = replacement
    var held: List[i32] = List.new()
    let ys = [4, 5]
    held = ys
    xs.push(held.len() as i32)
    xs
