// `with bench`: a function marked @[bench] is timed.
@[bench]
fn bench_sum_1000: (0..1000) |> sum()

@[bench]
fn bench_loop_10k:
    var x = 0
    for _ in 0..10000: x += 1
