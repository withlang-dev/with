//! expect-stdout: 1 a
//! expect-stdout: 2 b
//! expect-stdout: 1 2 3 4
//! expect-stdout: 11 22
//! expect-stdout: 0 x
//! expect-stdout: 1 y
fn main:
    let xs = [1, 2]
    let ys: List[str] = ["a", "b"]
    for (n, s) in xs |> zip(ys): print(f"{n} {s}")
    let zs = [3, 4]
    let all = xs |> chain(zs) |> map(f"{it}") |> collect[List]()
    print(all.join(" "))
    let sums = xs |> zip_with([10, 20], (a, b) => a + b) |> map(f"{it}") |> collect[List]()
    print(sums.join(" "))
    for (i, s) in (0..2) |> zip(["x", "y"]): print(f"{i} {s}")
