// Grow: push-built vectors inside a struct, 800 rounds of 100k rows each.
// Timed region: everything. Checksum: wrapping fold over the rows.
const ROUNDS: i64 = 800;
const ROWS: i64 = 100_000;

struct Table { xs: Vec<i64>, ys: Vec<i64>, ids: Vec<i64> }

fn next(mut x: u64) -> u64 { x ^= x << 13; x ^= x >> 7; x ^= x << 17; x }

impl Table {
    fn push_row(&mut self, r: u64, id: i64) {
        self.xs.push((r % 1000) as i64);
        self.ys.push(((r >> 10) % 1000) as i64);
        self.ids.push(id);
    }
    fn fold(&self) -> i64 {
        let mut total: i64 = 0;
        for i in 0..self.ids.len() {
            total = total.wrapping_add(self.xs[i] * 3 + self.ys[i] * 7 + self.ids[i]);
        }
        total
    }
}

fn main() {
    let start = std::time::Instant::now();
    let mut rng: u64 = 2463534242;
    let mut checksum: i64 = 0;
    for round in 0..ROUNDS {
        let mut table = Table { xs: Vec::new(), ys: Vec::new(), ids: Vec::new() };
        for i in 0..ROWS {
            rng = next(rng);
            table.push_row(rng, round * ROWS + i);
        }
        checksum = checksum.wrapping_add(table.fold());
    }
    let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;
    println!("rounds {} rows {}", ROUNDS, ROWS);
    println!("elapsed_ms {:.3}", elapsed_ms);
    println!("checksum {}", checksum);
}
