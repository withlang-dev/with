//! expect-stdout: pod: 1 then 2
//! expect-stdout: records: 100 one x | 200 two y
//! expect-stdout: into_iter: 100 one x | 200 two y

// #1689: `Vec.remove(i)` loads the element, shifts the buffer, then stores
// the loaded value into the caller's binding. For an element of 64 bytes or
// more the aggregate-copy lowering (compiler/LlvmBridge.w
// wl_lower_aggregate_copies) rewrote that store into a memmove from the
// buffer — positioned at the store, after the shift — so the removed value
// was whatever the shift left in slot i. A 24-byte element stayed a plain
// load and was never affected. Consuming iteration (`into_iter`, whose
// `next` is `remove(0)`) inherited it: every element read as the last.
type H { a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32, j: i32, k: i32, l: i32, m: i32, n: i32, o: i32, p: i32 }
type F { a: i32, b: i32, c: i32, m: str, n: str, h: str }

fn describe(kind: i32, at: i32) -> F:
    if kind == 1:
        return F { a: 7, b: at, c: at + 1, m: "one " ++ "x", n: "note", h: "help" }
    F { a: 7, b: at, c: at + 1, m: "two " ++ "y", n: "", h: "help2" }

fn records() -> Vec[F]:
    var out: Vec[F] = Vec.new()
    for i in 0..2:
        out.push(describe(i + 1, 100 * (i + 1)))
    out

fn main:
    var pods: Vec[H] = Vec.new()
    pods.push(H { a: 1, b: 0, c: 0, d: 0, e: 0, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0, m: 0, n: 0, o: 0, p: 0 })
    pods.push(H { a: 2, b: 0, c: 0, d: 0, e: 0, f: 0, g: 0, h: 0, i: 0, j: 0, k: 0, l: 0, m: 0, n: 0, o: 0, p: 0 })
    let first = pods.remove(0)
    print(f"pod: {first.a} then {pods.remove(0).a}")

    var rs = records()
    let r0 = rs.remove(0)
    let r1 = rs.remove(0)
    print(f"records: {r0.b} {r0.m} | {r1.b} {r1.m}")

    var all: Vec[F] = Vec.new()
    let found = records()
    for f in found.into_iter(): all.push(f)
    print(f"into_iter: {all[0].b} {all[0].m} | {all[1].b} {all[1].m}")
