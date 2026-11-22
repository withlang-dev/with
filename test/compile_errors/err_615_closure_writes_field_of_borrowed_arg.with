//! expect-check-fail: argument retains access to `y` which is mutably captured by a closure in the same call (§3.2)

// #615: a mutating call through a field of the captured place
// (`y.items.push`) was not seen as a write of `y`.
type Bag { items: List[i64] }

fn look(b: &Bag, body: fn() -> i32) -> i32:
    let first = &b.items[0]
    let r = body()
    print(*first)
    r

fn main:
    var y = Bag { items: [7] }
    print(look(y, () => {
        y.items.push(1)
        1
    }))
