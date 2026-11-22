use common

const V: i64 = 100000 // BENCH_N

fn main:
    let ne = V * 8
    var esrc: Vec[i32] = Vec.new()
    var edst: Vec[i32] = Vec.new()
    var start: Vec[i32] = Vec.new()
    for _ in 0..V + 1: start.push(0)
    var r: u64 = 12345
    for _ in 0..ne:
        r = xs_next(r)
        let u = xs_mod(r, V)
        esrc.push(u as i32)
        edst.push(xs_mod(r >> 24, V) as i32)
        start[u + 1] += 1
    for v in 0..V: start[v + 1] += start[v]
    var cursor = start.clone()
    var out: Vec[i32] = Vec.new()
    for _ in 0..ne: out.push(0)
    for e in 0..ne:
        let s: i32 = esrc[e]
        out[cursor[s]] = edst[e]
        cursor[s] += 1
    var dist: Vec[i32] = Vec.new()
    for _ in 0..V: dist.push(-1)
    var q: Vec[i32] = Vec.new()
    var total: i64 = 0
    var seed: u64 = 999
    for _ in 0..4:
        seed = xs_next(seed)
        let src = xs_mod(seed, V)
        for v in 0..V: dist[v] = -1
        q.clear()
        dist[src] = 0
        q.push(src as i32)
        var qh: i64 = 0
        while qh < q.len():
            let u: i32 = q[qh]
            qh += 1
            let d: i32 = dist[u]
            total += d
            for k in start[u]..start[u + 1]:
                let w: i32 = out[k]
                if dist[w] < 0:
                    dist[w] = d + 1
                    q.push(w)
    print(V + ne)
    print(total)
