//! expect-check-fail: view `fs` may originate from `n`, which no longer lives here

// #1594 / §12.4: a non-move closure is a view of `n`; pushing it into a
// container declared outside `n`'s scope stores a view that outlives its
// origin. The snapshot is spelled `move () => n * 10`.
fn main:
    var fs: Vec[fn() -> i32] = Vec.new()
    for i in 0..3:
        let n = i
        fs.push(() => n * 10)
    for k in 0..3: print(fs[k]())
