use common
use std.string.StringBuilder

const N: i64 = 500000 // BENCH_N
enum Event:
    Tick
    Move(i32, i16, i16)
    Say(i32, str)
    Quit(i32, u8)

fn word(seed: u64) -> str:
    var w = StringBuilder.new()
    var r = xs_next(seed)
    let n = 4 + xs_mod(r, 12)
    for _ in 0..n:
        r = xs_next(r)
        w.push_byte((97 + xs_mod(r, 26)) as u8)
    w.to_str()

fn main:
    var log: Vec[Event] = Vec.new()
    var r: u64 = 12345
    for _ in 0..N:
        r = xs_next(r)
        let k = xs_mod(r, 8)
        let id = xs_mod(r >> 3, 100000) as i32
        if k < 4:
            log.push(.Move(id, (xs_mod(r >> 20, 201) - 100) as i16, (xs_mod(r >> 40, 201) - 100) as i16))
        else if k < 6: log.push(.Say(id, word(r)))
        else if k < 7: log.push(.Quit(id, xs_mod(r >> 20, 256) as u8))
        else: log.push(.Tick)
    var total: i64 = 0
    for _ in 0..4:
        for event in log:
            total += match event:
                .Tick => 1
                .Move(id, dx, dy) => id + dx + dy
                .Say(id, text) => id + text.len() + text.byte_at(0)
                .Quit(id, code) => id + code
    print(log.len())
    print(total)
