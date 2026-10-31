//! expect-stdout: holder=7
//! expect-stdout: list=3
//! expect-stdout: choice=5
//! expect-stdout: memo=9

// A generic instance is Send when its own fields and payloads are, read at
// its arguments. The template records no type for a field spelled by a
// type parameter (`x: T`), and the check read that as "not Send": every
// generic struct and enum with such a field was refused by a channel. A
// `Memo` moves between threads (D172, §19.1: it is only not `Sync`).
use std.memo

type Holder[T] { x: T }

type Bag[T] { items: List[T] }

enum Choice[T]:
    Some(T)
    Empty

fn main:
    let (tx, rx) = chan[Holder[i64]](1)
    tx.send(Holder { x: 7 })
    match rx.recv():
        Some(h) => print(f"holder={h.x}")
        None => print("holder=none")

    let (btx, brx) = chan[Bag[i32]](1)
    btx.send(Bag { items: [1, 2, 3] })
    match brx.recv():
        Some(b) => print(f"list={b.items.len()}")
        None => print("list=none")

    let (ctx, crx) = chan[Choice[i32]](1)
    ctx.send(Choice.Some(5))
    match crx.recv():
        Some(Choice.Some(v)) => print(f"choice={v}")
        _ => print("choice=none")

    let cache: Memo[i32, i64] = Memo.new()
    cache.insert(1, 9)
    let (mtx, mrx) = chan[Memo[i32, i64]](1)
    mtx.send(cache)
    match mrx.recv():
        Some(m) => print(f"memo={m.get(1) ?? 0}")
        None => print("memo=none")
