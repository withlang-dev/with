//! expect-stdout: drop x
//! expect-stdout: drop big
//! expect-stdout: 4
//! expect-stdout: drop h2
//! expect-stdout: drop h1
//! expect-stdout: h1
//! expect-stdout: drop r2
//! expect-stdout: drop r1
//! expect-stdout: 1
//! expect-stdout: 0
//! expect-stdout: drop g2
//! expect-stdout: drop g1
//! expect-stdout: g1+1
//! expect-stdout: drop f1
//! expect-stdout: drop f2
//! expect-stdout: whole 2

// #3461 (§9.7): a subject moved with `move` is owned for every pattern
// form. `leak` never dropped its list: the variant bindings of the other
// arms took the subject and the list pattern only viewed it.
// What a list pattern does not bind is dropped once (`[h, ..]`,
// `[_, ..rest]`); `[]` on a consumed subject frees the buffer; and when a
// guard fails nothing has been taken apart for the next arm.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

enum E:
    A(xs: List[Tag])
    B(xs: List[Tag])

fn leak(e: E) -> i32:
    match move e:
        .A([h, ..rest]) => h.name.len() as i32 + rest.len() as i32
        .A(xs) => 0
        .B(xs) => xs.len() as i32

fn head_only(xs: List[Tag]) -> str:
    match move xs:
        [h, ..] => h.name
        [] => "empty"

fn rest_only(xs: List[Tag]) -> i32:
    match move xs:
        [_, ..rest] => rest.len() as i32
        [] => -1

fn empty_arm(xs: List[Tag]) -> i32:
    match move xs:
        [] => 0
        _ => 1

fn guarded(e: E, ok: bool) -> str:
    match move e:
        .A([h, ..rest]) if ok => f"{h.name}+{rest.len()}"
        .A(xs) => f"whole {xs.len()}"
        .B(xs) => f"b {xs.len()}"

fn main:
    print(leak(.A([Tag { name: "big" }, Tag { name: "x" }])))
    print(head_only([Tag { name: "h1" }, Tag { name: "h2" }]))
    print(rest_only([Tag { name: "r1" }, Tag { name: "r2" }]))
    let buf: List[Tag] = []
    print(empty_arm(buf))
    print(guarded(.A([Tag { name: "g1" }, Tag { name: "g2" }]), true))
    print(guarded(.A([Tag { name: "f1" }, Tag { name: "f2" }]), false))
