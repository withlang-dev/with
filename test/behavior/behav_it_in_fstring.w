//! expect-stdout: 1 2 3 | <1> <2> <3>

// §9.3.1: `it` may appear in any expression position, an f-string hole
// included. The hole's sub-parser saw `it` and dropped the fact, so the
// argument never became a closure ("undefined variable" on `__it`).
fn main:
    let nums: Vec[i32] = [1, 2, 3]
    let plain: Vec[str] = nums.iter() |> map(f"{it}") |> collect[Vec]()
    let wrapped: Vec[str] = nums.iter() |> map(f"<{it}>") |> collect[Vec]()
    print(plain.join(" ") ++ " | " ++ wrapped.join(" "))
