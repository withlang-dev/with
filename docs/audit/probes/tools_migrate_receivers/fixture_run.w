type Counter {
    n: i32,
}

impl Counter {
    fn get() -> i32: self.n
    mut fn bump(v: i32):
        self.n = self.n + v
    fn describe(name: str) -> str: name
}

fn main:
    var c = Counter { n: 1 }
    print(f"{c.get()}")
