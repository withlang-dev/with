//! expect-stdout: ok

// [A5] #607: sound borrow-iteration over a Vec[Drop], both `for w in &xs` / `for w in
// &h.field` and the underlying `.iter_ref()` form. The loop variable is `&W` (each
// element borrowed via VEC_GET_REF — no copy, no move), so:
//   - under-fire/soundness: each element drops EXACTLY once (the Vec's own drop),
//     never double (copy-then-drop) and never leaked;
//   - over-fire guard: borrowing does NOT consume the Vec, so it stays usable after
//     the loop and drops normally; non-Drop Vec iteration is unchanged.
// Floor-blind on both directions (no other Vec[Drop] on the floor), and single-field
// / owner_receiver greens don't catch field-vs-local — hence multi-element AND a
// field receiver here. Consuming `for w in xs` is intentionally NOT exercised (#607).

var DROPS = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        DROPS = DROPS + 1

type H { items: Vec[W] }

fn mk(a: i32, b: i32, c: i32) -> Vec[W]:
    let v: Vec[W] = Vec.new()
    v.push(W { tag: a })
    v.push(W { tag: b })
    v.push(W { tag: c })
    v

// `for w in &xs` over a local: read fields through &W; xs still usable afterwards.
fn local_amp() -> i32:
    let xs: Vec[W] = mk(1, 2, 3)
    var s = 0
    for w in &xs:
        s = s + w.tag
    s + (xs.len() as i32)            // over-fire guard: borrow didn't consume xs

// `for w in &h.items` over a struct field: the field-receiver case (would double-free
// if lowered as a header copy); reads fields, h.items still usable afterwards.
fn field_amp() -> i32:
    let h = H { items: mk(10, 20, 30) }
    var s = 0
    for w in &h.items:
        s = s + w.tag
    s + (h.items.len() as i32)

// The explicit `.iter_ref()` form on a field receiver (was a crash before #607 fix).
fn field_iter_ref() -> i32:
    let h = H { items: mk(100, 200, 300) }
    var s = 0
    for w in h.items.iter_ref():
        s = s + w.tag
    s

// Non-Drop Vec iteration must be unchanged (by-value, POD elements).
fn pod_iter() -> i32:
    let ns: Vec[i32] = Vec.new()
    ns.push(4)
    ns.push(5)
    var s = 0
    for n in ns:
        s = s + n
    s

fn main:
    DROPS = 0
    let a = local_amp()              // 1+2+3 + len 3 = 9; xs drops 3
    let b = field_amp()              // 10+20+30 + 3 = 63; h.items drops 3
    let c = field_iter_ref()         // 100+200+300 = 600; h.items drops 3
    let p = pod_iter()               // 9; no drops
    // DROPS == 9 ⇒ each of the 9 Drop elements dropped exactly once (no double, no leak)
    if a == 9 and b == 63 and c == 600 and p == 9 and DROPS == 9:
        print("ok")
    else:
        print_i32(DROPS)
