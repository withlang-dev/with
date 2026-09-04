fn neg() -> i64:
    -1

fn deref_sum(v: &Vec[i64]) -> i64:
    var t: i64 = 0
    for x in v:
        t = t + x
    t

fn rng(n: i64) -> i64:
    var t: i64 = 0
    for sp in 0..n:
        t = t + sp
    t

fn first(s: &str) -> str:
    s
