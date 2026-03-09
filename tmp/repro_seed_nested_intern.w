use InternPool

type Holder = {
    pool: InternPool,
}

impl Holder
    fn intern_drop(self: Holder, s: str) -> i32:
        self.pool.intern(s ++ ".drop")

fn main -> i32:
    let mut h = Holder {
        pool: InternPool.init(),
    }
    let a = h.intern_drop("abc")
    let b = h.intern_drop("abc")
    if a == b then 0 else 1
