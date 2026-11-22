//! expect-stdout: 3 7 5
//! expect-stdout: 1 7 3
// §9.9 (D95): `??` binds below the pipeline and above the comparisons, and
// is right-associative; `|` < `^` < `&`, as in C.
fn largest(xs: &List[i64]): xs.iter() |> max() ?? 0

fn main:
    let xs = [3, 1, 2]
    let none: Option[i64] = None
    let empty: List[i64] = List.new()
    let backup: Option[i64] = Some(7)
    let first = none ?? backup ?? 0
    print(f"{largest(xs)} {first} {if none ?? 5 > 4: largest(empty) + 5 else: 0}")
    print(f"{1 | 2 & 4} {6 ^ 3 & 1} {1 | 6 ^ 4}")
