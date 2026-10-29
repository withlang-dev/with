//! expect-check-fail: a `pub fn` declares its return type (Law 6); write `->` (D143)
// D143 / Law 6: a `pub` method that calls itself declares its return type,
// as a `pub fn` does.
pub type Counter { step: i32 }

impl Counter:
    pub fn run(n: i32):
        if n <= 0: 0 else: self.step + self.run(n - 1)

fn main:
    let c = Counter { step: 2 }
    print(f"{c.run(3)}")
