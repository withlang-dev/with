//! expect-debug-alloc: leak count=0
//! expect-stdout: 3 3 ab
//! expect-stdout: 0
//! expect-stdout: 2 bag! 2
//! expect-stdout: 33 -1

// #1354: a `var` destructure of non-Copy parts moves each part into its
// binding exactly once. The bindings are then mutated in place (`push`),
// replaced (`s = s ++ ...`, `v = Vec.new()` drops the old buffer), and
// dropped at scope exit; the subject aggregate owns nothing afterwards. The
// wildcard's `str` still drops once. A refutable `var` pattern moves the
// payload only on the success path. (The failure path of a let-else over an
// owned Err payload is #1365.)

type Bag { items: Vec[i32], name: str, n: i32 }

fn make -> (Vec[i32], str):
    var v: Vec[i32] = Vec.new()
    v.push(1)
    (v, "a".clone())

fn make_bag -> Bag:
    var items: Vec[i32] = Vec.new()
    items.push(7)
    Bag { items, name: "bag".clone(), n: 1 }

fn items(k: i32) -> Option[Vec[str]]:
    if k == 0: return None
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    Some(v)

fn refutable(k: i32) -> i32:
    var Some(v) = items(k) else: return -1
    v.push("b".clone())
    v.push("c".clone())
    30 + v.len() as i32

fn main:
    var (v, s) = make()
    v.push(2)
    v.push(3)
    s = s ++ "b"
    print(f"{v.len()} {v[2]} {s}")
    v = Vec.new()
    print(f"{v.len()}")

    var Bag { items, name, n } = make_bag()
    items.push(8)
    name = name ++ "!"
    n += 1
    print(f"{items.len()} {name} {n}")

    var (_, keep) = ("dropped".clone(), 1)
    keep += 0
    print(f"{refutable(1) + keep - 1} {refutable(0)}")
