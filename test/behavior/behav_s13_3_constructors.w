//! expect-stdout: empty 0
//! expect-stdout: once 5
//! expect-stdout: repeat 7 7 7
//! expect-stdout: unfold 1 2 4 8 16 32 64 128 256 512
//! expect-stdout: from_fn 1 2 3
use std.collections.EmptyIter
fn show[T, I: Iter[T]](seq: I) -> str: seq |> map(f"{it}") |> collect[List]() |> join(" ")
fn main:
    let none: EmptyIter[i32] = Iter.empty()
    print(f"empty {none |> count()}")
    print("once " ++ show(Iter.once(5)))
    print("repeat " ++ show(Iter.repeat(7) |> take(3)))
    print("unfold " ++ show(Iter.unfold(1, n => Some((n, n * 2))) |> take(10)))
    var n = 0
    let counted = Iter.from_fn(move () =>
        if n < 3:
            n += 1
            Some(n)
        else: None) |> collect[List]()
    print("from_fn " ++ (counted |> map(f"{it}") |> collect[List]() |> join(" ")))
