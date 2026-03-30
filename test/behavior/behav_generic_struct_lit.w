//! expect-stdout: ok
type Pair[T] { first: T, second: T }

fn sum_pair(p: Pair[i32]) -> i32: p.first + p.second

fn main:
    let p = Pair { first: 10, second: 20 }
    assert(sum_pair(p) == 30)
    print("ok")
