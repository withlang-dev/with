// Buffers: chunked-I/O shaped churn of 8 to 64 KiB blocks, 32 live at once.
// Timed region: everything. Checksum: wrapping sum of the words written.
use std.time

const ITERATIONS: i32 = 2000000
const RING: i32 = 32

type Ring { slots: Vec[Vec[u64]] }

fn main:
    let start = now_ns()
    var ring = Ring { slots: Vec.with_capacity(RING) }
    for _ in 0..RING: ring.slots.push(Vec.new())
    var checksum: u64 = 0
    for i in 0..ITERATIONS:
        let words = 1024 * (1 + (i % 8))
        var block: Vec[u64] = Vec.with_capacity(words)
        // Touch a contiguous prefix; the block's size is the point, not its fill.
        for j in 0..(words / 64):
            let value = (i as u64) *% 2654435761 +% (j as u64)
            block.push(value)
            checksum = checksum +% value
        ring.slots[i % RING] = block
    let elapsed_ms = (now_ns() - start) as f64 / 1000000.0
    print(f"iterations {ITERATIONS} ring {RING}")
    print(f"elapsed_ms {elapsed_ms:.3}")
    print(f"checksum {checksum}")
