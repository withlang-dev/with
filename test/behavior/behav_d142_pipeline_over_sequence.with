//! expect-stdout: 1 2 3 5 5 7 9
//! expect-stdout: 0 42
//! expect-stdout: 2 4 6
//! expect-stdout: 2 3

// D142 (§13.5): a sequence on the left of `|>` iterates by the rule `for`
// uses, and a slice has `iter()` (§13.1). The quicksort as written: `rest`
// is a slice, `rest |> filter(..)` sees its views, and `collect[List]()`
// over views of values builds a list of the values (D111, D139).
fn quicksort(xs: List[isize]) -> List[isize]:
    match xs:
        [] => []
        [pivot, ..rest] =>
            let smaller = rest |> filter(it < pivot) |> collect[List]()
            let larger  = rest |> filter(it >= pivot) |> collect[List]()
            quicksort(smaller) ++ [pivot] ++ quicksort(larger)

fn show(xs: &List[isize]):
    var out = ""
    for x in xs: out = out ++ f"{x} "
    print(out.trim())

fn main:
    show(quicksort([5, 3, 9, 1, 5, 7, 2]))
    print(f"{quicksort([]).len()} {quicksort([42])[0]}")
    // A List on the left of `|>`.
    let xs: List[i32] = [1, 2, 3]
    let doubled: List[i32] = xs |> map(it * 2) |> collect[List]()
    print(f"{doubled[0]} {doubled[1]} {doubled[2]}")
    // A slice's own `iter()`, spelled and in a `for`.
    let tail = xs.rest()
    var sum = 0
    for x in tail.iter(): sum = sum + x
    print(f"{tail.iter() |> count()} {sum - 2}")
