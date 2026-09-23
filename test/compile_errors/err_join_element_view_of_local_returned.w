//! expect-check-fail: returned view may outlive its origin 'v'

// #1406: the returned join views elements of the local `v`, which is dropped
// when `pick` returns. Before the fix this compiled and returned a dangling
// view.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn pick(c: bool) -> &str:
    let v = mkv()
    if c: v[0] else: v[1]

fn main:
    print(pick(true))
