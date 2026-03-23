//! expect-stdout: ok
type Pair[T] = { first: T, second: T }

fn Pair.sum(self: Pair[T]) -> T: self.first + self.second
fn Pair.get_first(self: Pair[T]) -> T: self.first

fn main:
    let p: Pair[i32] = Pair{ first: 10, second: 20 }
    let s = p.sum()
    assert(s == 30)
    let f = p.get_first()
    assert(f == 10)
    print("ok")
