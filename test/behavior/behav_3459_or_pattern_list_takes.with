//! expect-stdout: drop a2
//! expect-stdout: drop a1
//! expect-stdout: a1+1
//! expect-stdout: drop b1
//! expect-stdout: b1+0
//! expect-stdout: drop x
//! expect-stdout: drop big
//! expect-stdout: big+1
//! expect-stdout: drop small
//! expect-stdout: drop y
//! expect-stdout: B2

// #3459 (§9.7): an or-pattern alternative that takes a list apart. Each
// alternative logs what it took; a failed guard puts back only what the
// alternative that matched took, and the next arm binds the list whole.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

enum E:
    A(xs: List[Tag], n: i32)
    B(n: i32, xs: List[Tag])
    Z

fn first(e: E) -> str:
    match move e:
        .A([h, ..rest], _) | .B(_, [h, ..rest]) => f"{h.name}+{rest.len()}"
        _ => "none"

fn guarded(e: E) -> str:
    match move e:
        .A([h, ..rest], n) | .B(n, [h, ..rest]) if n > 5 => f"{h.name}+{rest.len()}"
        .A(xs, _) => f"A{xs.len()}"
        .B(_, xs) => f"B{xs.len()}"
        _ => "none"

fn main:
    print(first(.A([Tag { name: "a1" }, Tag { name: "a2" }], 1)))
    print(first(.B(2, [Tag { name: "b1" }])))
    print(guarded(.A([Tag { name: "big" }, Tag { name: "x" }], 9)))
    print(guarded(.B(1, [Tag { name: "small" }, Tag { name: "y" }])))
