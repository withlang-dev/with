// Words: string building, hashing, and map lookup over 30M generated words.
// Timed region: everything. Checksum: order-independent FNV mix of the counts
// folded with an FNV of a 1000-line report built from lookups.
use std::collections::HashMap;
use std::fmt::Write;

const WORDS: usize = 30_000_000;
const VOCAB: u64 = 60_000;
const HOT: u64 = 600;

fn next(mut x: u64) -> u64 {
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    x
}

fn spell(id: u64) -> String {
    let mut v = id + 676;
    let mut s = String::new();
    while v > 0 {
        s.push((b'a' + (v % 26) as u8) as char);
        v /= 26;
    }
    s
}

fn fnv(s: &str) -> u64 {
    let mut h: u64 = 14695981039346656037;
    for b in s.bytes() {
        h = (h ^ b as u64).wrapping_mul(1099511628211);
    }
    h
}

fn main() {
    let start = std::time::Instant::now();
    let mut rng: u64 = 88172645463325252;
    let mut counts: HashMap<String, i32> = HashMap::new();
    for _ in 0..WORDS {
        rng = next(rng);
        let id = if rng % 10 < 3 { (rng >> 8) % HOT } else { (rng >> 8) % VOCAB };
        let word = spell(id);
        let seen = counts.get(&word).copied().unwrap_or(0);
        counts.insert(word, seen + 1);
    }
    let mut mix: u64 = 0;
    for (word, count) in &counts {
        mix = mix.wrapping_add((*count as u64).wrapping_mul(fnv(word)));
    }
    let mut report = String::new();
    for id in 0..1000u64 {
        let word = spell(id);
        let count = counts.get(&word).copied().unwrap_or(0);
        write!(report, "{}:{}\n", word, count).unwrap();
    }
    let checksum = mix ^ fnv(&report);
    let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;
    println!("distinct {} report_bytes {}", counts.len(), report.len());
    println!("elapsed_ms {:.3}", elapsed_ms);
    println!("checksum {}", checksum);
}
