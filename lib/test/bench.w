// lib/test/bench — Benchmark harness for With
//
// Usage:
//   @[bench]
//   fn bench_my_thing():
//       let v = Vec.from([3, 1, 4, 1, 5])
//       v.sort()
//
// The harness calls the function repeatedly, auto-calibrating
// iteration count to fill ~1 second, then reports ns/op.

use std.time

extern fn with_str_len(s: str) -> i32

type Bench {
    target_ns: i64,
    n: i64,
    elapsed_ns: i64,
    bytes_per_op: i64,
}

fn Bench.new() -> Bench:
    Bench {
        target_ns: 1000000000,
        n: 0,
        elapsed_ns: 0,
        bytes_per_op: 0,
    }

fn Bench.set_bytes(self: &mut Bench, b: i64):
    self.bytes_per_op = b

fn Bench.ns_per_op(self: &Bench) -> i64:
    if self.n == 0:
        return 0
    self.elapsed_ns / self.n

fn Bench.run(self: &mut Bench, f: fn() -> void):
    // Go-style calibration: start at n=1, ramp up until ~1s elapsed
    self.n = 1
    var last_n: i64 = 0
    var last_ns: i64 = 0
    var done = false
    while not done:
        let t0 = now_ns()
        var i: i64 = 0
        while i < self.n:
            f()
            i = i + 1
        self.elapsed_ns = now_ns() - t0

        if self.elapsed_ns >= self.target_ns or self.n >= 1000000000:
            done = true
        else:
            // predictN: estimate iterations to fill target_ns
            last_n = self.n
            last_ns = self.elapsed_ns
            if last_ns <= 0:
                // Sub-nanosecond per call — grow aggressively
                self.n = self.n * 100
            else:
                self.n = self.target_ns * last_n / last_ns
                self.n = self.n + self.n / 5
                if self.n > last_n * 100:
                    self.n = last_n * 100
            if self.n < last_n + 1:
                self.n = last_n + 1
            if self.n > 1000000000:
                self.n = 1000000000

fn Bench.report(self: &Bench, name: str):
    let ns = self.ns_per_op()
    let pad_len = 40 - with_str_len(name)
    print(name)
    var pi = 0
    while pi < pad_len:
        print(" ")
        pi = pi + 1
    if self.bytes_per_op > 0 and ns > 0:
        let mb_s = self.bytes_per_op * 1000 / ns
        println(f"{self.n}\t{ns} ns/op\t{mb_s} MB/s")
    else:
        println(f"{self.n}\t{ns} ns/op")
