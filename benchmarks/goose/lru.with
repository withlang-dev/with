use common
use std.collections.HashMap

const N: i64 = 2000000 // BENCH_N
const CAP: i64 = N / 8
const KEYS: i64 = CAP * 2
type Node { key: i32, val: i32, prev: i32, next: i32 }
type Cache { nodes: Vec[Node], free: Vec[i32], map: HashMap[i32, i32] }

impl Cache:
    mut fn unlink(index: i32):
        let p: i32 = self.nodes[index].prev
        let q: i32 = self.nodes[index].next
        self.nodes[p].next = q
        self.nodes[q].prev = p

    mut fn front(index: i32):
        let q: i32 = self.nodes[0].next
        self.nodes[index].prev = 0
        self.nodes[index].next = q
        self.nodes[q].prev = index
        self.nodes[0].next = index

    mut fn discard(index: i32):
        self.unlink(index)
        self.map.remove(self.nodes[index].key)
        self.free.push(index)

    mut fn insert(key: i32):
        let node = Node { key: key, val: key % 1000, prev: 0, next: 0 }
        var index: i32 = self.nodes.len() as i32
        if self.free.len() > 0:
            index = self.free.pop().unwrap()
            self.nodes[index] = node
        else: self.nodes.push(node)
        self.map.insert(key, index)
        self.front(index)

fn main:
    var cache = Cache { nodes: Vec.new(), free: Vec.new(), map: HashMap.new() }
    cache.nodes.push(Node { key: -1, val: 0, prev: -1, next: 1 })
    cache.nodes.push(Node { key: -1, val: 0, prev: 0, next: -1 })
    var count: i64 = 0
    var hits: i64 = 0
    var misses: i64 = 0
    var removes: i64 = 0
    var r: u64 = 12345
    for _ in 0..N:
        r = xs_next(r)
        let a = xs_mod(r, KEYS)
        let key = (a * a / KEYS) as i32
        let index: i32 = cache.map.get(key) ?? -1
        if xs_mod(r >> 40, 16) == 0:
            if index >= 0:
                cache.discard(index)
                count -= 1
                removes += 1
            continue
        if index >= 0:
            cache.nodes[index].val += 1
            cache.unlink(index)
            cache.front(index)
            hits += 1
            continue
        misses += 1
        if count == CAP:
            let last: i32 = cache.nodes[1].prev
            cache.discard(last)
            count -= 1
        cache.insert(key)
        count += 1
    var walk: u64 = 0
    var vals: i64 = 0
    var cur: i32 = cache.nodes[0].next
    while cache.nodes[cur].key >= 0:
        walk = walk *% 31 +% (cache.nodes[cur].key as u64)
        vals += cache.nodes[cur].val
        cur = cache.nodes[cur].next
    print(hits)
    print(misses)
    print(removes)
    print(count)
    print(walk)
    print(vals)
