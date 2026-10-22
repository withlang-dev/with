//! expect-stdout: 1 2 3 5 5 7 9
//! expect-stdout: 3 6
//! expect-stdout: 4

// D143 (§9.1): a package-local function with no return type that calls
// itself. The paths that do not call it decide the type (`[pivot]` through
// `++` here), the self-calls take it, and `[] => []` takes it as its demand.
fn quicksort(xs: List[isize]):
    match xs:
        [] => []
        [pivot, ..rest] =>
            let smaller = rest |> filter(it < pivot) |> collect[List]()
            let larger  = rest |> filter(it >= pivot) |> collect[List]()
            quicksort(smaller) ++ [pivot] ++ quicksort(larger)

fn depth(xs: &List[i32], i: isize):
    if i >= xs.len(): 0 else: 1 + depth(xs, i + 1)

fn total(xs: &List[i32], i: isize, acc: i32):
    if i >= xs.len(): return acc
    total(xs, i + 1, acc + xs[i])

// A recursive procedure: a missing `else` makes it `Unit` (D43 rule 1).
var ticks = 0
fn countdown(n: i32):
    if n > 0:
        ticks = ticks + 1
        countdown(n - 1)

fn main:
    var out = ""
    for x in quicksort([5, 3, 9, 1, 5, 7, 2]): out = out ++ f"{x} "
    print(out.trim())
    let xs: List[i32] = [1, 2, 3]
    print(f"{depth(xs, 0)} {total(xs, 0, 0)}")
    countdown(4)
    print(f"{ticks}")
