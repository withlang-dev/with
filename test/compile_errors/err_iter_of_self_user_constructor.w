//! expect-error: argument retains access to `bag` which is mutably captured by a closure in the same call (§15.7)

// §13.2 — user libraries may mark iterator constructors with
// `@[iter_of_self]`. The returned iterator then retains shared access to the
// receiver, so a sibling closure cannot mutably capture that receiver.

type BorrowBag { count: i32 }

type BorrowIter { value: i32, done: bool }

impl Iter[i32] for BorrowIter:    fn next(mut self:
    Self) -> Option[i32]:
        if self.done:
            return .None
        self.done = true
        .Some(self.value)

impl BorrowBag:
    fn add(mut self: Self, value: i32) -> i32:
        self.count = self.count + value
        self.count

    @[iter_of_self]
    fn borrowed_iter(self: &Self) -> BorrowIter:
        BorrowIter { value: self.count, done: false }

fn consume_borrowed(iter: BorrowIter, cb: fn(i32) -> i32) -> i32:
    var sum = 0
    for x in iter:
        sum = sum + cb(x)
    sum

fn main:
    var bag = BorrowBag { count: 1 }
    let _ = consume_borrowed(bag.borrowed_iter(), item => bag.add(item))
