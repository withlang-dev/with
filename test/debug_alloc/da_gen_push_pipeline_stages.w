//! expect-debug-alloc: leak count=0
//! expect-stdout: 10
//! expect-stdout: 6 10 16
//! expect-stdout: defer words
//! expect-stdout: w0! w2!
//! expect-stdout: defer words
//! expect-stdout: 2
//! expect-stdout: 5

// D69 (§13.3, §13.4): the ordered stages take a Gen[T] and are Gens, so a
// pipeline over an endless generator is lazy, and `take` stops the whole
// chain at the generator's yield — its defer runs, its owned elements drop
// once. A stage's closure parameter is typed from the element (`it` is an
// i64 here, a str there).
use std.generators.{map, filter, take, collect}

gen fn fibonacci -> i64:
    var a: i64 = 0
    var b: i64 = 1
    loop:
        yield a
        let next = a + b
        a = b
        b = next

gen fn words(n: i32) -> str:
    defer:
        print("defer words")
    for i in 0..n:
        yield f"w{i}"

fn main:
    let first_10 = fibonacci() |> take(10) |> collect[Vec]()
    print(first_10.len())
    let picked = fibonacci() |> map(it * 2) |> filter(it > 4) |> take(3) |> collect[Vec]()
    print(f"{picked[0]} {picked[1]} {picked[2]}")
    var out = ""
    for w in words(100) |> filter(it != "w1") |> map(it ++ "!") |> take(2):
        out = out ++ (if out.len() > 0: " " else: "") ++ w
    print(out)
    let lens = words(2) |> map(it.len()) |> collect[Vec]()
    print(lens.len())
    var n = 0
    for v in fibonacci() |> take(5):
        n += 1
    print(n)
