//! expect-stdout: 18
//! expect-stdout: 2

// D118 step (a): `List` is accepted wherever the growable sequence is
// named: a type, a parameter, an associated call, a `collect` target, a
// pattern subject. Step (c) makes it the type's own name.
type Bag { items: List[str] }

fn total(xs: &List[i32]) -> i32:
    var t: i32 = 0
    for x in xs: t = t + x
    t

fn main:
    var a: List[i32] = List.new()
    a.push(1)
    let b: List[i32] = [2, 3]
    let c = b.iter() |> map(it * 2) |> collect[List]()
    print(total(&a) + total(&b) + total(&c) + c.len() as i32)
    let bag = Bag { items: ["x", "y"] }
    print(bag.items.len())
