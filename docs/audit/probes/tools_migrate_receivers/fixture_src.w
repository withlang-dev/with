type Counter {
    n: i32,
}

impl Counter {
    fn get(self: &Self) -> i32: self.n
    fn bump(mut self: Self, v: i32):
        self.n = self.n + v
    fn describe(name: str) -> str: name
}

fn main:
    var c = Counter { n: 1 }
    print(f"{c.get()}")
