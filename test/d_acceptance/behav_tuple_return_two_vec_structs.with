//! expect-stdout: 3

// #731: a tuple return pairing two List-of-struct payloads lowered to
// identity-distinct LLVM types on the caller and callee sides (duplicate
// generic-inst tids each minted their own named __with.List type), and the
// call-site store rejected the structurally-identical value. The collection
// type caches are dual-keyed now; keep the shape pinned.

type A { x: i32 }
type B { y: i32 }

fn make() -> (List[A], List[B]):
    var a: List[A] = List.new()
    a.push(A { x: 1 })
    var b: List[B] = List.new()
    b.push(B { y: 2 })
    b.push(B { y: 3 })
    (a, b)

fn main:
    let (ra, rb) = make()
    print(int_to_string(ra.len() + rb.len()))
