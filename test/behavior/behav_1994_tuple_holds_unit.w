//! expect-stdout: 5 4/4
//! expect-stdout: 1 1 8/8
//! expect-stdout: unit 7 9
//! expect-stdout: some 3

// #1994 (with-abi.md §1): `Unit` has zero size in a layout, so a tuple
// element of type Unit occupies no bytes — `(Unit, i32)` is 4 bytes, both
// elements at offset 0. Its LLVM member is the empty struct; the value is
// carried as the `i32` Unit carrier only where one is materialized. Before,
// the element lowered to `void` inside the tuple body and LLVM aborted the
// compile in `DataLayout::getTypeSizeInBits` (SIGTRAP, rc 133).

type TU = (Unit, i32)
type TV = (i64, Unit)

fn unit(): ()

fn pair(n: i32) -> (Unit, i32): (unit(), n)

fn main:
    let t: (Unit, i32) = (unit(), 5)
    print(f"{t.1} {comptime TU.size()}/{size_of[TU]()}")
    var v: Vec[(i64, Unit)] = Vec.new()
    v.push((1, unit()))
    let (n, _) = v[0]
    print(f"{v.len()} {n} {comptime TV.size()}/{size_of[TV]()}")
    let (u, x) = pair(7)
    let w = t.0
    print(f"unit {x} {pair(9).1}")
    let o: Option[(Unit, i32)] = Some(pair(3))
    match o:
        .Some(p) => print(f"some {p.1}")
        .None => print("none")
