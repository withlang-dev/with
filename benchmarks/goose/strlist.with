use common
use std.string.StringBuilder

const N: i64 = 200000 // BENCH_N

fn main:
    var text = StringBuilder.new()
    var r: u64 = 12345
    for _ in 0..N:
        r = xs_next(r)
        let wl = 3 + xs_mod(r, 18)
        for _ in 0..wl:
            r = xs_next(r)
            text.push_byte((97 + xs_mod(r, 26)) as u8)
        text.push_byte(32)
    let source = text.to_str()
    var words: Vec[str] = Vec.new()
    for word in source.split(" "):
        if word.len() > 0: words.push(word.clone())
    var total: i64 = 0
    for _ in 0..4:
        for w in words:
            total += w.len() + w.byte_at(0) + w.byte_at(w.len() - 1)
    print(words.len())
    print(total)
