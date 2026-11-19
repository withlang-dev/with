//! expect-check-fail: the receiver `x` holds its place for the call, and a closure in the same call writes it (§3.2)

// #615 (D218): the callee holds a view into `self.items` across the call
// of its closure; the closure pushes to `x.items`, the list reallocates,
// and the view read freed memory (it printed 0 for an element that was 7).
type Bag { items: List[i64], n: i32 }
impl Bag:
    mut fn scope(body: fn() -> i32) -> i32:
        let first = &self.items[0]
        let r = body()
        print(*first)
        r

fn main:
    var x = Bag { items: [7], n: 0 }
    let r = x.scope(() => {
        for i in 0..100000: x.items.push(1)
        x.n
    })
    print(r)
