//! expect-stdout: 7 7
//! expect-stdout: 7
// #1557: a type recursive through a Vec (`N { next: Vec[N] }`). Codegen
// inlined each element's drop glue into the Vec's element loop, so N's glue
// expanded N -> Vec[N] -> N without end and the compiler overflowed its
// stack (exit 139) on the first drop of a Vec[N]. The element drop now calls
// N's named drop fn. Every node drops exactly once: seven Tags, seven drops.

global var dropped = 0

type Tag { id: i32 }
impl Drop for Tag:
    move fn drop():
        dropped = dropped + 1

type N { tag: Tag, next: Vec[N] }

fn node(id: i32, kids: Vec[N]) -> N: N { tag: Tag { id: id }, next: kids }

fn count(t: &N) -> i32:
    var total = 1
    for k in t.next:
        total = total + count(k)
    total

fn main:
    let empty: Vec[N] = Vec.new()
    var leaves: Vec[N] = Vec.new()
    for i in 0..4:
        leaves.push(node(10 + i, Vec.new()))
    var mid: Vec[N] = Vec.new()
    mid.push(node(2, leaves))
    mid.push(node(3, Vec.new()))
    let root = node(1, mid)
    let before = count(&root)
    drop(root)
    print(f"{before} {dropped}")
    print(f"{empty.len() + 7}")
