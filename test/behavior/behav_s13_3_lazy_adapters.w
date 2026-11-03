//! expect-stdout: chunks 2 2 1
//! expect-stdout: windows 1,2 2,3 3,4
//! expect-stdout: dedup 1 2 3 1
//! expect-stdout: unique 1 2 3
//! expect-stdout: intersperse 1 0 2 0 3
//! expect-stdout: scan 1 3 6 10
//! expect-stdout: flatten 1 2 3 4
//! expect-stdout: flatten_into 1 1 2 2
//! expect-stdout: peek 1
//! expect-stdout: next 1 2
//! expect-stdout: take_while 2
//! expect-stdout: filter_map 3 4
fn show[T, I: Iter[T]](seq: I) -> str: seq |> map(f"{it}") |> collect[List]() |> join(" ")
fn main:
    let xs = [1, 2, 3, 4, 5]
    print("chunks " ++ show(xs |> chunks(2) |> map(it.len())))
    print("windows " ++ show([1, 2, 3, 4] |> windows(2) |> map(w => w |> map(f"{it}") |> collect[List]() |> join(","))))
    print("dedup " ++ show([1, 1, 2, 2, 2, 3, 1] |> dedup()))
    print("unique " ++ show([1, 2, 1, 3, 2] |> unique()))
    print("intersperse " ++ show([1, 2, 3] |> intersperse(0)))
    print("scan " ++ show([1, 2, 3, 4] |> scan(0, (s, x) => (s + x, s + x))))
    print("flatten " ++ show([[1, 2], [3], [4]] |> flatten()))
    print("flatten_into " ++ show([1, 2] |> map(x => [x, x]) |> flatten()))
    let two = [1, 2]
    var p = two |> peekable()
    print(f"peek {p.peek().unwrap()}")
    print(f"next {p.next().unwrap()} {p.next().unwrap()}")
    print(f"take_while {xs |> take_while(it < 3) |> count()}")
    print("filter_map " ++ show(xs |> filter_map(x => if x > 2 and x < 5: Some(x) else: None)))
