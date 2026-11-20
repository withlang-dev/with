//! expect-stdout: a
//! expect-stdout: drop d
//! expect-stdout: drop c
//! expect-stdout: c
//! expect-stdout: 7
//! expect-stdout: end
//! expect-stdout: drop a
//! expect-stdout: drop b

// D223 with D117: where a name has an observing and a taking form
// (`first`), `Type.name` is the observing one, and a wanted function type
// whose first parameter is taken by value selects the taking one, as the
// receiver's ownership does at a call.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

fn take_first(f: fn(List[Tag]) -> Option[Tag], xs: List[Tag]) -> str:
    match f(xs):
        Some(t) => t.name
        None => "none"

fn main:
    let first = List[Tag].first
    let xs = [Tag { name: "a" }, Tag { name: "b" }]
    match first(xs):
        Some(t) => print(t.name)
        None => print("none")
    print(take_first(List[Tag].first, [Tag { name: "c" }, Tag { name: "d" }]))
    let owned: fn(List[i32]) -> Option[i32] = List[i32].first
    print(owned([7, 8]) ?? 0)
    print("end")
