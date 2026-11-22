//! expect-stdout: 1 1 1

// #3453: what stays legal. A function with a `mut` parameter is called
// directly, generic or not, and writes the caller's place.
type Bag { n: i32 }

fn bump(mut b: Bag) -> i32:
    b.n += 1
    b.n

fn grow[T](mut xs: List[T], v: T): xs.push(v)

fn main:
    var x = Bag { n: 0 }
    let r = bump(x)
    var ys: List[i32] = []
    grow(ys, 4)
    print(f"{r} {x.n} {ys.len()}")
