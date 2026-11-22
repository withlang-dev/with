//! expect-stdout: 3
//! expect-stdout: 1
//! expect-stdout: 0

// #1317: a mutation of the iterated collection is harmless when the loop
// ends right after it — an unlabeled `break` of that loop or a `return` is
// the next statement, so no iteration reads the collection through the
// view again. Find-then-grow and find-then-clear stay accepted.

type KV { key: str, n: i32 }
type Bag { items: List[KV] }

impl Bag:
    mut fn clear_if_found(n: i32) -> bool:
        for e in self.items:
            if e.n == n:
                self.items.clear()
                return true
        false

fn main:
    var xs: List[KV] = List.new()
    xs.push(KV { key: "a", n: 1 })
    xs.push(KV { key: "b", n: 2 })
    for e in xs:
        if e.n == 2:
            xs.push(KV { key: "c", n: 3 })
            break
    print(f"{xs.len()}")
    var b = Bag { items: List.new() }
    b.items.push(KV { key: "a", n: 1 })
    if b.clear_if_found(1):
        print("1")
    print(f"{b.items.len()}")
