//! expect-stdout: ok

enum Kind { A | B }
type TaggedNode { kind: Kind, x: i32 }
type PlainNode { op: i32, a: i32, b: i32 }

fn first_nonzero_i32(xs: List[i32]) -> bool:
    if xs.len() == 0 as i64:
        return false
    xs[0] != 0

fn first_nonzero_i64(xs: List[i64]) -> bool:
    if xs.len() == 0 as i64:
        return false
    xs[0] != 0 as i64

fn main:
    let xs0: List[i32] = List.new()
    assert(not first_nonzero_i32(xs0))
    let xs1: List[i32] = List.new()
    xs1.push(1)
    xs1.push(2)
    assert(first_nonzero_i32(xs1))
    assert(first_nonzero_i32(List[i32][1, 2]))
    assert(not first_nonzero_i32(List[i32][0, 2]))

    let xs64: List[i64] = List.new()
    xs64.push(0 as i64)
    assert(not first_nonzero_i64(xs64))
    let xs64_nonzero: List[i64] = List.new()
    xs64_nonzero.push(7 as i64)
    xs64_nonzero.push(0 as i64)
    assert(first_nonzero_i64(xs64_nonzero))
    assert(not first_nonzero_i64(List[i64][0, 2]))
    assert(first_nonzero_i64(List[i64][7, 0]))

    let tagged: List[TaggedNode] = List.new()
    tagged.push(TaggedNode { kind: .A, x: 1 })
    let first_tagged = tagged[0]
    assert(first_tagged.kind == .A)

    let plain: List[PlainNode] = List.new()
    plain.push(PlainNode { op: 3, a: -1, b: 0 })
    let first_plain = plain[0]
    assert(first_plain.op == 3)
    assert(first_plain.a == -1)
    assert(first_plain.b == 0)

    print("ok")
