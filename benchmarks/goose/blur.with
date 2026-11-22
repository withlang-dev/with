use common

const W: i64 = 1024 // BENCH_N
type Image { pixels: Vec[u8] }

impl Image:
    mut fn blur(src: &Image):
        for y in 1..W - 1:
            for x in 1..W - 1:
                let i = y * W + x
                let sum = (src.pixels[i - W - 1] as i32) + (src.pixels[i - W] as i32) * 2 + (src.pixels[i - W + 1] as i32) + (src.pixels[i - 1] as i32) * 2 + (src.pixels[i] as i32) * 4 + (src.pixels[i + 1] as i32) * 2 + (src.pixels[i + W - 1] as i32) + (src.pixels[i + W] as i32) * 2 + (src.pixels[i + W + 1] as i32)
                self.pixels[i] = (sum >> 4) as u8

fn main:
    var a = Image { pixels: Vec.new() }
    var b = Image { pixels: Vec.new() }
    var r: u64 = 12345
    for _ in 0..W * W:
        r = xs_next(r)
        a.pixels.push(xs_mod(r, 256) as u8)
        b.pixels.push(0)
    for _ in 0..8:
        b.blur(a)
        a.blur(b)
    var total: i64 = 0
    for v in a.pixels: total += v
    print(W)
    print(total)
