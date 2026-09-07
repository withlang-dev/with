fn neg() -> i64:
    - 1
fn rng(n: i64) -> i64:
    var t: i64 = 0
    for sp in 0 .. n:
        t = t + sp
    t
fn main:
    print(neg().to_string())
    print(rng(5).to_string())
