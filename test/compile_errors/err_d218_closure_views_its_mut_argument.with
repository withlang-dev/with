//! expect-check-fail: cannot mutate `bag` while `f` is a live view into it

// D218 (Eric, 2026-11-19): the closure's own captures at an indirect
// call. `f` captures `bag`, so it holds a view of it for as long as it
// exists; passing `bag` to its `mut` parameter would write under that view.
type Bag { n: i32 }

fn main:
    var bag = Bag { n: 0 }
    let f = (mut b: Bag) => {
        b.n += 1
        bag.n
    }
    print(f(bag))
