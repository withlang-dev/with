//! expect-check-fail: cannot mutate `v` while `x` is a live view into it

// #1406: a match join of element views (one arm indexed by a pattern
// binding) keeps `v` as the view's origin; `v[0] = …` drops the element `x`
// still views.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn g(o: Option[i32]):
    var v = mkv()
    let x = match o:
        Some(i) => v[i]
        None => v[0]
    v[1] = "zzz".clone()
    print(x)

fn main:
    g(Some(1))
