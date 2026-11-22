//! expect-stdout: 3 4 9

// #2760: a bracket literal Sema typed `List[T]` is a list to the compile-time
// evaluator too. It stayed an array value, so `.len()` on a `&List`
// parameter and `push` on a binding were "not comptime-evaluable yet".
fn count(args: &List[str]) -> i32:
    var n = 0
    for i in 0..args.len(): n = n + 1
    n

fn grown() -> i32:
    let xs = [1, 2, 3]
    xs.push(4)
    xs.len() as i32

fn total(xs: &List[i32]) -> i32:
    var sum = 0
    for x in xs: sum = sum + x
    sum

const N: i32 = count(["a", "b", "c"])
const G: i32 = grown()
const T: i32 = total([2, 3, 4])

fn main:
    print(f"{N} {G} {T}")
