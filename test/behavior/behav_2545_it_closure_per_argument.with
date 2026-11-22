//! expect-stdout: 9
//! expect-stdout: 3 4

// #2545: `it` opens one implicit closure per call argument. A pipeline
// stage's `it` after another stage's was refused as a nested `it`
// ("E0951") because the parser counted the depth per expression, not per
// argument.
fn main:
    let xs = [1, 2, 3]
    let sq = xs |> map(it * it) |> collect[List]()
    print(f"{sq[2]}")
    let bumped = xs |> filter(it > 1) |> map(it + 1) |> collect[List]()
    print(f"{bumped[0]} {bumped[1]}")
