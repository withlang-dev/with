//! expect-stdout: 1 true 6 3
// #2142: a pipeline over views of the elements. `position` takes the
// element like every other predicate; a view of a view compares as the
// value it observes; `sum` and `max` over views of a Copy element yield the
// element.
fn main:
    let names: Vec[str] = ["b".to_lower(), "a".to_lower()]
    let at = names.iter() |> position(it == "a")
    let kept = names.iter() |> filter(it.len() > 0) |> collect[Vec]()
    let xs = [1, 2, 3]
    let total = xs.iter_ref() |> sum()
    let top = (xs.iter_ref() |> max()) ?? 0
    print(f"{at ?? -1} {kept[1] == "a"} {total} {top}")
