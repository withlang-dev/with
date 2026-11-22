//! expect-debug-alloc: leak count=0
//! expect-stdout: 36 ada 7 bo
// #2772: a program's own types named like std's type parameters. A struct
// `U` mapped through iter_map[T, U, I] was rewritten by name to the
// specialization's U (i32): MIR built Mapped[&i32, i32, ListIter[i32]] and
// stopped on a field-type miss. A struct `T` hid std's own `T` in
// `impl[T] Iterable[T] for List[T]`: "unknown type 'T'" inside std.
type U { name: str, age: i32 }
type T { n: i32, tag: str }

fn main:
    let us: List[U] = [U { name: "ada", age: 36 }]
    let ts: List[T] = [T { n: 7, tag: "bo" }]
    var ages = 0
    for a in us.iter() |> map(it.age):
        ages = ages + a
    let names: List[str] = us.iter() |> map(it.name) |> collect[List]()
    let ns = ts.iter() |> fold(0, (acc, t) => acc + t.n)
    let tags: List[str] = ts.iter() |> map(it.tag) |> collect[List]()
    print(f"{ages} {names[0]} {ns} {tags[0]}")
