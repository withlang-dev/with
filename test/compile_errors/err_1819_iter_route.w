//! expect-check-fail: call to `Count.next` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `for` over an Iter[T] calls its `next()` each time
// round (§13.5), and `next` writes G while an element view of G is live.
// A call writes every global its callee writes.

var G: List[str] = List.new()

type Count { n: i32 }

impl Iter[i32] for Count:
    fn next(mut self: Self) -> Option[i32]:
        for i in 0..64: G.push(f"item{i}")
        if self.n == 0:
            return .None
        self.n = self.n - 1
        .Some(self.n)

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    let c = Count { n: 2 }
    for i in c:
        print(f"{i}")
    print(r)
