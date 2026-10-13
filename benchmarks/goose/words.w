use common
use std.string.StringBuilder
use std.collections.HashMap

const N: i64 = 500000 // BENCH_N

fn main:
    let vocab = N / 10 + 16
    var dict: Vec[str] = Vec.new()
    var r: u64 = 12345
    for _ in 0..vocab:
        var w = StringBuilder.new()
        r = xs_next(r)
        let n = 3 + xs_mod(r, 12)
        for _ in 0..n:
            r = xs_next(r)
            w.push_byte((97 + xs_mod(r, 26)) as u8)
        dict.push(w.to_str())
    var text = StringBuilder.new()
    for _ in 0..N:
        r = xs_next(r)
        let a = xs_mod(r, vocab)
        text.push_str(dict[a * a / vocab])
        text.push_byte(32)
    let source = text.to_str()
    var words: Vec[str] = Vec.new()
    for word in source.split(" "):
        if word.len() > 0: words.push(word.clone())
    var counts: HashMap[str, i32] = HashMap.new()
    for word in words:
        let count: i32 = counts.get(word) ?? 0
        counts.insert(word.clone(), count + 1)
    var total: i64 = 0
    for (word, count) in counts:
        total += count * (word.len() + word.byte_at(0))
    print(words.len())
    print(counts.len())
    print(total)
