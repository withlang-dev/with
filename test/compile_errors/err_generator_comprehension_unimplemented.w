//! expect-check-fail: a comprehension clause over a generator (Gen[T]) is not implemented yet (#1727)

gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

fn main:
    let v = [x * 2 for x in upto(3)]
    print(v.len())
