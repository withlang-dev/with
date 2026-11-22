//! expect-check-fail: cannot assign through a read-only place

type Point { x: i32, y: i32 }

fn try_mutate(p: &Point):
    p.x = 99   // error: mutation through &T param is forbidden

fn main:
    let p = Point { x: 1, y: 2 }
    try_mutate(&p)
