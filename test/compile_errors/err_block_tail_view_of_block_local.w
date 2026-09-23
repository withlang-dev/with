//! expect-check-fail: view may outlive its origin 'w', which is dropped at the end of this block

// #1406: an inner block's tail may yield a view of a binding declared outside
// it, never of one declared inside it — `w` is dropped when the block ends.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn pick(c: bool, d: bool) -> &str:
    if c:
        let w = mkv()
        if d: w[0] else: w[1]
    else:
        "z"

fn main:
    print(pick(true, true))
