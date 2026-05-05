// Aggregate Copy is opt-in. `type T: Copy { ... }` allows by-value escape without `move`.

type Pair: Copy {
    first: i32,
    second: i32,
}

fn identity(p: Pair) -> Pair:
    p

fn main:
    let p = Pair { first: 3, second: 4 }
    let q = identity(p)
    assert(p.first == 3)
    assert(p.second == 4)
    assert(q.first == 3)
    assert(q.second == 4)
