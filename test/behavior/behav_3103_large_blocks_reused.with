//! expect-stdout: 900600
// #3103: large List buffers made and dropped per iteration reuse their
// mapping; the sums say every reused block came back zeroed and whole.
fn main:
    var total: i64 = 0
    for round in 0..300:
        var xs: List[i64] = []
        for i in 0..3000: xs.push(i)
        for x in xs: total = total + (if x == 2999: 1 else: 0) + (if x == 0: 1 else: 0)
        var ys: List[i64] = []
        for i in 0..1500: ys.push(2)
        for y in ys: total = total + y
    print(f"{total}")
