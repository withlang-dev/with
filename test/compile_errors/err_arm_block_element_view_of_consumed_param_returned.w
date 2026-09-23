//! expect-check-fail: returned view may outlive its origin 'v'

// #1406 / #718: an arm block's tail flows into the return; `v` is consumed by
// `pick` and dies when it returns. Take `v: &Vec[str]` instead.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn pick(v: Vec[str], c: bool) -> &str:
    if c:
        let i = 0
        v[i]
    else:
        v[1]

fn main:
    print(pick(mkv(), true))
