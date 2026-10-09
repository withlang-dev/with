//! expect-stdout: 7 7
//! expect-stdout: 7
// #1557: a type recursive through a List (`N { next: List[N] }`). Codegen
// inlined each element's drop glue into the List's element loop, so N's glue
// expanded N -> List[N] -> N without end and the compiler overflowed its
// stack (exit 139) on the first drop of a List[N]. The element drop now calls
// N's named drop fn. Every node drops exactly once: seven Tags, seven drops.

global var dropped = 0

type Tag { id: i32 }
impl Drop for Tag:
    move fn drop():
        dropped = dropped + 1

type N { tag: Tag, next: List[N] }

fn node(id: i32, kids: List[N]) -> N: N { tag: Tag { id: id }, next: kids }

fn count(t: &N) -> i32:
    var total = 1
    for k in t.next:
        total = total + count(k)
    total

fn main:
    let empty: List[N] = List.new()
    var leaves: List[N] = List.new()
    for i in 0..4:
        leaves.push(node(10 + i, List.new()))
    var mid: List[N] = List.new()
    mid.push(node(2, leaves))
    mid.push(node(3, List.new()))
    let root = node(1, mid)
    let before = count(&root)
    drop(root)
    print(f"{before} {dropped}")
    print(f"{empty.len() + 7}")
