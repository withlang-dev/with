// Grow: push-built vectors inside a struct, 800 rounds of 100k rows each.
// Timed region: everything. Checksum: wrapping fold over the rows.
use std.time

const ROUNDS: i32 = 800
const ROWS: i32 = 100000

type Table { xs: Vec[i64], ys: Vec[i64], ids: Vec[i64] }

fn next(state: u64) -> u64:
    var x = state
    x = x ^ (x << (13 as u32))
    x = x ^ (x >> (7 as u32))
    x = x ^ (x << (17 as u32))
    x

extend Table:
    fn push_row(mut self: Self, r: u64, id: i64):
        self.xs.push((r % 1000) as i64)
        self.ys.push(((r >> (10 as u32)) % 1000) as i64)
        self.ids.push(id)

    fn fold(self: &Self) -> i64:
        var total: i64 = 0
        for i in 0..self.ids.len():
            total = total +% (self.xs[i] * 3 + self.ys[i] * 7 + self.ids[i])
        total

fn main:
    let start = now_ns()
    var rng: u64 = 2463534242
    var checksum: i64 = 0
    for round in 0..ROUNDS:
        var table = Table { xs: Vec.new(), ys: Vec.new(), ids: Vec.new() }
        for i in 0..ROWS:
            rng = next(rng)
            table.push_row(rng, (round * ROWS + i) as i64)
        checksum = checksum +% table.fold()
    let elapsed_ms = (now_ns() - start) as f64 / 1000000.0
    print(f"rounds {ROUNDS} rows {ROWS}")
    print(f"elapsed_ms {elapsed_ms:.3}")
    print(f"checksum {checksum}")
