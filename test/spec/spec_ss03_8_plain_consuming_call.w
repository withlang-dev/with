//! expect-stdout: ok

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

type Pair { x: i32, y: i32 } with Copy

fn take(r: Resource) -> i32:
    r.id

fn sum_pair(p: Pair) -> i32:
    p.x + p.y

fn main:
    let r = Resource { id: 1 }
    assert(take(r) == 1)

    let r2 = Resource { id: 2 }
    assert(take(move r2) == 2)

    let p = Pair { x: 3, y: 4 }
    assert(sum_pair(copy p) == 7)
    assert(p.x == 3)
    print("ok")
