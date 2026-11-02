//! expect-stdout: 3 4
//! expect-stdout: 2
//! expect-stdout: ok

// D186 (§13.3): the adapter that skips the first n elements is `skip(n)`
// and its predicate form `skip_while`; `drop(value)` stays the prelude's
// release form, so `xs |> skip(2)` can never read as a destructor call.

fn main:
    let xs = [1, 2, 3, 4]
    let tail = xs |> skip(2) |> collect[List]()
    print(f"{tail[0]} {tail[1]}")
    let rest = xs |> skip_while(it < 3) |> count()
    print(f"{rest}")
    print("ok")
