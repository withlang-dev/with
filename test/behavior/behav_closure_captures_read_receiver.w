//! expect-stdout: 8
//! expect-stdout: 8
//! expect-stdout: 7 9
//! expect-stdout: 15

// #2025 (§12.4, §9.5): a closure in a read-mode `fn` method captures the
// receiver by place. The receiver is typed `&Self` and held as the caller's
// place, so the capture is a slot holding that address — the closure read
// the receiver's own bytes as the address and faulted. `mut fn` and
// `move fn` receivers were already right.

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

type C {
    count: i32,
    items: List[i32],
}

impl C:
    fn plus(x: i32) -> i32: apply(y => y + self.count, x)
    fn plus_bare(x: i32) -> i32: apply(y => y + count, x)
    fn shifted -> List[i32]: items.iter() |> map(it + count) |> collect[List]()
    mut fn plus_mut(x: i32) -> i32: apply(y => y + self.count, x)

fn main:
    var c = C { count: 5, items: [2, 4] }
    print(f"{c.plus(3)}")
    print(f"{c.plus_bare(3)}")
    let s = c.shifted()
    print(f"{s[0]} {s[1]}")
    print(f"{c.plus_mut(10)}")
