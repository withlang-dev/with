//! expect-stdout: ok
// §13.1.1.4: a user ephemeral Iter[T] type is returned by value and driven,
// and propagates through an ephemeral parameter.
type MIter ephemeral { limit: i64, pos: i64 }
impl Iter[i64] for MIter:
    fn next(mut self: Self) -> Option[i64]:
        if self.pos >= self.limit:
            return .None
        let v = self.pos
        self.pos = self.pos + 1
        .Some(v)
fn counter(n: i64) -> MIter:
    MIter { limit: n, pos: 0 }
fn drive(iter: MIter) -> i64:
    var sum: i64 = 0
    for x in iter:
        sum = sum + x
    sum
fn main:
    var sum: i64 = 0
    var iter = counter(3)
    while let Some(x) = iter.next():
        sum = sum + x
    assert(sum == 3)
    let s2 = drive(counter(4))
    assert(s2 == 6)
    print("ok")
