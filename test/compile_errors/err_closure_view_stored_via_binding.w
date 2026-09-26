//! expect-check-fail: view `fs` may originate from `n`, which no longer lives here

// #1594 / §12.4: the same store through a let-bound closure.
fn main:
    var fs: Vec[fn() -> i32] = Vec.new()
    if true:
        let n = 7
        let f = () => n * 10
        fs.push(f)
    print(fs[0]())
