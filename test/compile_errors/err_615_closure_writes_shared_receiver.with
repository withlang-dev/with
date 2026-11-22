//! expect-check-fail: the receiver `x` holds its place for the call, and a closure in the same call writes it (§3.2)

// #615: the same hole through a read-only receiver.
type Bag { items: List[i64] }
impl Bag:
    fn scope(body: fn() -> i32) -> i32:
        let first = &self.items[0]
        let r = body()
        print(*first)
        r

fn main:
    var x = Bag { items: [7] }
    print(x.scope(() => {
        x.items.push(1)
        1
    }))
