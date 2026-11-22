//! expect-stdout: sorted 1 2 3
//! expect-stdout: sorted_by 3 2 1
//! expect-stdout: group_by odd=1,3 even=2
//! expect-stdout: group_by_str a=apple,avocado b=banana
fn show(xs: &List[isize]) -> str: xs |> map(f"{it}") |> collect[List]() |> join(",")
fn main:
    print("sorted " ++ show([3, 1, 2] |> sorted()).replace(",", " "))
    print("sorted_by " ++ show([3, 1, 2] |> sorted_by((a, b) => b.cmp(a))).replace(",", " "))
    let g = [1, 2, 3] |> group_by(x => if x % 2 == 1: "odd" else: "even")
    print("group_by odd=" ++ show(g.get("odd").unwrap()) ++ " even=" ++ show(g.get("even").unwrap()))
    let words = ["apple", "banana", "avocado"]
    let by_first = words |> group_by(w => w[0..1])
    print("group_by_str a=" ++ by_first.get("a").unwrap().join(",") ++ " b=" ++ by_first.get("b").unwrap().join(","))
