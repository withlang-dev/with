// Buffers: chunked-I/O shaped churn of 8 to 64 KiB blocks, 32 live at once.
// Timed region: everything. Checksum: wrapping sum of the words written.
const ITERATIONS: usize = 2_000_000;
const RING: usize = 32;

fn main() {
    let start = std::time::Instant::now();
    let mut ring: Vec<Vec<u64>> = (0..RING).map(|_| Vec::new()).collect();
    let mut checksum: u64 = 0;
    for i in 0..ITERATIONS {
        let words = 1024 * (1 + (i % 8));
        let mut block: Vec<u64> = Vec::with_capacity(words);
        for j in 0..(words / 64) {
            let value = (i as u64).wrapping_mul(2654435761).wrapping_add(j as u64);
            block.push(value);
            checksum = checksum.wrapping_add(value);
        }
        ring[i % RING] = block;
    }
    let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;
    println!("iterations {} ring {}", ITERATIONS, RING);
    println!("elapsed_ms {:.3}", elapsed_ms);
    println!("checksum {}", checksum);
}
