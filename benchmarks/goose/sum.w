use common

const N: i64 = 1000000 // BENCH_N

fn main:
    var data: Vec[i32] = Vec.new()
    var r: u64 = 12345
    for _ in 0..N:
        r = xs_next(r)
        data.push(xs_mod(r, 1000) as i32)
    var total: i64 = 0
    for p in 0..8:
        for x in data: total += x ^ p
    print(data.len())
    print(total)
