// Words: string building, hashing, and map lookup over 30M generated words.
// Timed region: everything. Checksum: order-independent FNV mix of the counts
// folded with an FNV of a 1000-line report built from lookups.
use std.time
use std.string.StringBuilder
use std.collections.HashMap

const WORDS: i32 = 30000000
const VOCAB: i64 = 60000
const HOT: i64 = 600

fn next(state: u64) -> u64:
    var x = state
    x = x ^ (x << (13 as u32))
    x = x ^ (x >> (7 as u32))
    x = x ^ (x << (17 as u32))
    x

// Base-26 spelling of id + 676, least significant letter first: 3+ letters.
fn spell(id: i64) -> str:
    var v = id + 676
    var sb = StringBuilder.new()
    while v > 0:
        sb.push_byte((97 + (v % 26)) as u8)
        v = v / 26
    sb.to_str()

fn fnv(s: &str) -> u64:
    var h: u64 = 14695981039346656037
    for i in 0..s.len():
        h = (h ^ (s.byte_at(i) as u64)) *% 1099511628211
    h

fn main:
    let start = now_ns()
    var rng: u64 = 88172645463325252
    var counts: HashMap[str, i32] = HashMap.new()
    for _ in 0..WORDS:
        rng = next(rng)
        let roll = (rng % 10) as i64
        let id = if roll < 3: ((rng >> (8 as u32)) % (HOT as u64)) as i64 else: ((rng >> (8 as u32)) % (VOCAB as u64)) as i64
        let word = spell(id)
        let seen: i32 = counts.get(word) ?? 0
        counts.insert(word, seen + 1)
    var mix: u64 = 0
    for (word, count) in counts:
        mix = mix +% ((count as u64) *% fnv(word))
    var report = StringBuilder.new()
    for id in 0..1000:
        let word = spell(id as i64)
        let count: i32 = counts.get(word) ?? 0
        report.push_str(word)
        report.push_byte(58)
        report.push_str(f"{count}")
        report.push_byte(10)
    let text = report.to_str()
    let checksum = mix ^ fnv(text)
    let elapsed_ms = (now_ns() - start) as f64 / 1000000.0
    print(f"distinct {counts.len()} report_bytes {text.len()}")
    print(f"elapsed_ms {elapsed_ms:.3}")
    print(f"checksum {checksum}")
