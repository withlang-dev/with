//! expect-stdout: 6
//! expect-stdout: 3

// D178: `for x in self` in a read method walks a derived iterator; the
// iterator's own field writes (its `next` stepping through a `mut fn` of
// its own) are the temporary's, never the collection's, so the method
// stays `fn`. The iterator is generic: the for-desugar demands its `next()`
// with the iterable standing in as the receiver node (#912), which is where
// the write once landed on the collection (std's BTreeMap walked its mlib
// cursor the same way).
type Bag[T] { items: List[T] }

type BagIter[T] ephemeral { src: &Bag[T], at: i32 }

impl[T] BagIter[T]:
    mut fn step(): self.at += 1

impl[T: Copy] Iter[T] for BagIter[T]:
    mut fn next() -> Option[T]:
        if self.at >= self.src.items.len() as i32: return None
        let v = self.src.items[self.at]
        self.step()
        Some(v)

impl[T: Copy] Bag[T]:
    @[iter_of_self]
    fn iter() -> BagIter[T]: BagIter { src: self, at: 0 }
    fn count() -> i32:
        var n = 0
        for _ in self: n += 1
        n

impl Bag[i32]:
    fn total() -> i32:
        var sum = 0
        for v in self: sum += v
        sum

fn main:
    let bag: Bag[i32] = Bag { items: [1, 2, 3] }
    print(f"{bag.total()}")
    print(f"{bag.count()}")
