//! expect-check-fail: returned view may outlive its origin 'v'

// #1406 / #718: an arm block's tail flows into the return; `v` is consumed by
// `pick` and dies when it returns. Take `v: &List[str]` instead.

fn mkv() -> List[str]:
    var v: List[str] = List.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn pick(v: List[str], c: bool) -> &str:
    if c:
        let i = 0
        v[i]
    else:
        v[1]

fn main:
    print(pick(mkv(), true))
