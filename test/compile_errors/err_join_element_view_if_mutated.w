//! expect-check-fail: cannot mutate `v` while `x` is a live view into it

// #1406 (§3.8 join rule 3, §21.1 rules 1 and 10): both arms are views of
// elements of `v`, so the joined view carries `v` as its origin. The pushes
// reallocate v's buffer while `x` is live; before the fix this compiled and
// `print(x)` read freed memory.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn g(c: bool):
    var v = mkv()
    let x = if c: v[0] else: v[1]
    for i in 0..100:
        v.push("q".clone())
    print(x)

fn main:
    g(true)
