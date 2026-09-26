//! expect-stdout: 1
//! expect-debug-alloc: leak count=0

// §13.5 / #1490: a refutable `for` pattern over consuming iteration drops
// the elements it skips — `(1, "b")` is moved out of the iterator and
// nothing else owns it.
fn main:
    var ps: Vec[(i32, str)] = Vec.new()
    ps.push((0, "a".clone()))
    ps.push((1, "b".clone()))
    var n = 0
    for (0, s) in ps.into_iter():
        n = n + s.len() as i32
    print(n)
