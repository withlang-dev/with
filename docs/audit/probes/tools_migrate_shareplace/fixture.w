type Pair {
    a: i64,
    b: i64,
}

fn sum(p: Pair) -> i64: p.a + p.b

fn main:
    let p = Pair { a: 1, b: 2 }
    print(f"{sum(p)}")
