// Probe p3a: Vec get/remove/pop happy path (T23: loud vs silent).
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    if v.get(0) == 10:
        print("vget-0-ok")
    if v.get(2) == 30:
        print("vget-2-ok")
    let rem: i32 = v.remove(0)
    if rem == 10:
        print("vremove-value-ok")
    if v.len() == 2:
        print("vremove-len-ok")
    if v.get(0) == 20:
        print("vremove-shift-ok")
    let p: Option[i32] = v.pop()
    if p.is_some():
        print("vpop-some-ok")
    if p.unwrap() == 30:
        print("vpop-value-ok")
    var e: Vec[i32] = Vec.new()
    let pe: Option[i32] = e.pop()
    if pe.is_none():
        print("vpop-empty-none-ok")
    print("p3a-done")
