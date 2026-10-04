//! expect-stdout: 3 7

// #2066: a method is not a free function. A method, a trait method and a
// `T.m` function may share a module global's name; only a free function
// and a global of one name are two values under one name.

const limit: i32 = 3

type Gauge { n: i32 }

trait Bounded:
    fn limit() -> i32

impl Gauge:
    fn limit() -> i32: self.n

fn main:
    let g = Gauge { n: 7 }
    print(f"{limit} {g.limit()}")
