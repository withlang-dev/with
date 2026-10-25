// D120 copy-on-write value-list microbenchmarks (d120-implementation-plan.md):
//   1. Push loop through a struct field (`self.items.push(i)`).
//   2. Element-write loop through a parameter (`xs[i] = v`).
//   3. Share-then-mutate (`var b = a; b.push(i)`), forcing the CoW copy.
//
// Prints nanoseconds per operation (median of three rounds).
//
//     with run test/benchmark/cow_value_lists.w

use std.collections
use std.time

type Holder {
    items: List[i64],
}

impl Holder:
    mut fn push_n(n: i64):
        for i in 0..n:
            self.items.push(i)

fn elem_write_param(xs0: List[i64], rounds: i64) -> i64:
    var xs = xs0
    let n = xs.len()
    for r in 0..rounds:
        for i in 0..n:
            xs[i] = i + r
    xs[n - 1]

fn share_then_mutate_round(base: &List[i64], copies: i64) -> i64:
    var sum: i64 = 0
    for c in 0..copies:
        var dup = *base
        dup.push(c)
        sum = sum + dup[dup.len() - 1]
    sum

fn median3(a: i64, b: i64, c: i64) -> i64:
    if a <= b:
        if b <= c: return b
        if a <= c: return c
        return a
    if a <= c: return a
    if b <= c: return c
    b

fn bench_field_push(n: i64) -> i64:
    var times: List[i64] = List.new()
    for _ in 0..3:
        var h = Holder { items: List.with_capacity(n) }
        let t0 = now_ns()
        h.push_n(n)
        let t1 = now_ns()
        assert(h.items.len() == n)
        times.push(t1 - t0)
    median3(times[0], times[1], times[2])

fn bench_param_write(n: i64, passes: i64) -> i64:
    var seed: List[i64] = List.with_capacity(n)
    for i in 0..n:
        seed.push(i)
    var times: List[i64] = List.new()
    for _ in 0..3:
        let t0 = now_ns()
        let last = elem_write_param(seed, passes)
        let t1 = now_ns()
        assert(last == (n - 1) + (passes - 1))
        times.push(t1 - t0)
    median3(times[0], times[1], times[2])

fn bench_share_then_mutate(len: i64, copies: i64) -> i64:
    var base: List[i64] = List.with_capacity(len)
    for i in 0..len:
        base.push(i)
    var times: List[i64] = List.new()
    for _ in 0..3:
        let t0 = now_ns()
        let sum = share_then_mutate_round(&base, copies)
        let t1 = now_ns()
        assert(sum == copies * (copies - 1) / 2 and base.len() == len)
        times.push(t1 - t0)
    median3(times[0], times[1], times[2])

fn main:
    let n_push: i64 = 200000
    let n_write: i64 = 20000
    let write_passes: i64 = 20
    let share_len: i64 = 256
    let share_copies: i64 = 10000
    let push_ns = bench_field_push(n_push)
    let write_ns = bench_param_write(n_write, write_passes)
    let share_ns = bench_share_then_mutate(share_len, share_copies)
    let total_writes = n_write * write_passes
    print("benchmark                 ops        total ms   ns/op")
    print("------------------------  ---------  ---------  -----")
    print(f"field-push                {n_push}     {push_ns / 1000000}          {push_ns / n_push}")
    print(f"param-element-write       {total_writes}     {write_ns / 1000000}          {write_ns / total_writes}")
    print(f"share-then-mutate (256)   {share_copies}      {share_ns / 1000000}          {share_ns / share_copies}")
