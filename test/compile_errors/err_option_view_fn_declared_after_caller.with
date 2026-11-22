//! expect-check-fail: cannot mutate `v` while `r` is a live view into it
// §21.1 Rules 6 and 10 (#1473): an `Option[&T]` result carries its origins
// through the transparent carrier, whatever the declaration order.
fn main:
    var v: List[i32] = List.new()
    v.push(1)
    let r = find(v)
    v.push(2)
    print(f"{r.unwrap()}")
fn find(xs: &List[i32]) -> Option[&i32]: if xs.len() > 0: Some(&xs[0]) else: None
