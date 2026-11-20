//! expect-stdout: 2
//! expect-stdout: 2
//! expect-stdout: 6
//! expect-stdout: drop t1
//! expect-stdout: drop t2

// D218 (§3.8a): a closure's `mut` parameter is the caller's place, which
// the caller still owns; the closure body never drops it. (It did: after
// `push(ys, 5)` the caller's list was freed and read as empty, and a list
// of resources would have dropped its elements twice.)
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

fn main:
    var ys = [1]
    let push = (mut r: List[i32], a: i32) => r.push(a)
    push(ys, 5)
    print(ys.len())
    var zs: List[i32] = [1]
    push(zs, 6)
    print(zs.len())
    print(zs[1])
    var tags = [Tag { name: "t1" }]
    let push_tag = (mut r: List[Tag], t: Tag) => r.push(t)
    push_tag(tags, Tag { name: "t2" })
