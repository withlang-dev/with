use common

const N: i64 = 1000000 // BENCH_N
type Item { key: i32, val: i32 }

fn main:
    var items: Vec[Item] = Vec.new()
    var marks: Vec[i64] = Vec.new()
    var r: u64 = 12345
    for i in 0..N:
        r = xs_next(r)
        items.push(Item { key: xs_mod(r, 1000000) as i32, val: (i % 97) as i32 })
        if i % 64 == 0: marks.push(i)
    var total: i64 = 0
    for item in items: total += item.key
    var mt: i64 = 0
    for i in marks: mt += items[i].val
    print(items.len())
    print(marks.len())
    print(total)
    print(mt)
