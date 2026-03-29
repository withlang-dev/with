fn do_sum():
    var sum = 0
    for i in 0..1000:
        sum = sum + i

@[bench]
fn bench_sum_1000():
    do_sum()

fn bench_loop_10k():
    var x = 0
    for i in 0..10000:
        x = x + 1
