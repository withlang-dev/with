use InternPool

fn main -> i32:
    let mut pool = InternPool.init()
    let a = pool.intern("abc")
    let b = pool.intern("abc")
    if a == b then 0 else 1
