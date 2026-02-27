// Test generic struct with multiple type params
type Pair = { first: i32, second: i32 }

fn swap(p: Pair) -> Pair:
    Pair { first: p.second, second: p.first }

fn sum(p: Pair) -> i32:
    p.first + p.second

fn main -> i32:
    let p = Pair { first: 10, second: 20 }
    let s = swap(p)
    println(s.first)
    println(s.second)
    println(sum(p))
