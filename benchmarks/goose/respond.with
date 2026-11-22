use common
use std.string.StringBuilder

const N: i64 = 100000 // BENCH_N
type Item { sku: str, qty: i64, price: i64 }
type Response { id: i64, user: str, items: Vec[Item] }
type Renderer { out: StringBuilder }

fn name_of(seed: u64) -> str:
    var s = StringBuilder.new()
    var r = xs_next(seed)
    let n = 3 + xs_mod(r, 8)
    let odd = xs_mod(r >> 8, 8) == 0
    for i in 0..n:
        r = xs_next(r)
        if odd and i == 1: s.push_byte(if xs_mod(r, 2) == 0: 34 else: 92)
        else: s.push_byte((97 + xs_mod(r, 26)) as u8)
    s.to_str()

fn sku_of(seed: u64) -> str:
    var s = StringBuilder.new()
    var r = xs_next(seed)
    s.push_byte((65 + xs_mod(r, 26)) as u8)
    s.push_byte((65 + xs_mod(r >> 8, 26)) as u8)
    for _ in 0..4:
        r = xs_next(r)
        s.push_byte((48 + xs_mod(r, 10)) as u8)
    s.to_str()

fn make_items(seed: u64, n: i64) -> Vec[Item]:
    var items: Vec[Item] = Vec.new()
    var r = seed
    for _ in 0..n:
        r = xs_next(r)
        items.push(Item { sku: sku_of(r), qty: 1 + xs_mod(r >> 8, 5), price: 100 + xs_mod(r >> 16, 99900) })
    items

impl Renderer:
    mut fn integer(v: i64):
        if v == 0:
            self.out.push_byte(48)
            return
        var d = v
        var digits: [u8; 24] = [0; 24]
        var n: i64 = 0
        while d > 0:
            digits[n] = (48 + d % 10) as u8
            n += 1
            d /= 10
        while n > 0:
            n -= 1
            self.out.push_byte(digits[n])

    mut fn string(s: &str):
        self.out.push_byte(34)
        for i in 0..s.len():
            let c = s.byte_at(i) as u8
            if c == 34 or c == 92: self.out.push_byte(92)
            self.out.push_byte(c)
        self.out.push_byte(34)

    mut fn render(response: &Response):
        self.out.push_str("{\"id\":")
        self.integer(response.id)
        self.out.push_str(",\"user\":")
        self.string(response.user)
        self.out.push_str(",\"items\":[")
        var total: i64 = 0
        var first = true
        for item in response.items:
            if not first: self.out.push_byte(44)
            first = false
            self.out.push_str("{\"sku\":")
            self.string(item.sku)
            self.out.push_str(",\"qty\":")
            self.integer(item.qty)
            self.out.push_str(",\"price\":")
            self.integer(item.price)
            self.out.push_byte(125)
            total += item.qty * item.price
        self.out.push_str("],\"total\":")
        self.integer(total)
        self.out.push_byte(125)

fn handle(seed: u64) -> (u64, i64):
    let r = xs_next(seed)
    let response = Response { id: xs_mod(r >> 4, 1000000), user: name_of(r >> 8), items: make_items(r >> 16, 1 + xs_mod(r, 8)) }
    var renderer = Renderer { out: StringBuilder.new() }
    renderer.render(response)
    let text = renderer.out.to_str()
    var h: u64 = 14695981039346656037
    for i in 0..text.len(): h = (h ^ (text.byte_at(i) as u64)) *% 1099511628211
    (h, text.len())

fn main:
    var seed: u64 = 12345
    var h: u64 = 0
    var bytes: i64 = 0
    for i in 0..N:
        seed = xs_next(seed)
        let (hh, length) = handle(seed)
        h = h ^ (hh *% 31 +% (i as u64))
        bytes += length
    print(N)
    print(bytes)
    print(h)
