//! expect-debug-alloc: leak count=0
//! expect-stdout: 3 3 ab
//! expect-stdout: 0
//! expect-stdout: 2 bag! 2
//! expect-stdout: 33 -1

// #1354: a `var` destructure of non-Copy parts moves each part into its
// binding exactly once. The bindings are then mutated in place (`push`),
// replaced (`s = s ++ ...`, `v = List.new()` drops the old buffer), and
// dropped at scope exit; the subject aggregate owns nothing afterwards. The
// wildcard's `str` still drops once. A refutable `var` pattern moves the
// payload only on the success path. (The failure path of a let-else over an
// owned Err payload is #1365.)

type Bag { items: List[i32], name: str, n: i32 }

fn make -> (List[i32], str):
    var v: List[i32] = List.new()
    v.push(1)
    (v, "a")

fn make_bag -> Bag:
    var items: List[i32] = List.new()
    items.push(7)
    Bag { items, name: "bag", n: 1 }

fn items(k: i32) -> Option[List[str]]:
    if k == 0: return None
    var v: List[str] = List.new()
    v.push("a")
    Some(v)

fn refutable(k: i32) -> i32:
    var Some(v) = items(k) else: return -1
    v.push("b")
    v.push("c")
    30 + v.len() as i32

fn main:
    var (v, s) = make()
    v.push(2)
    v.push(3)
    s = s ++ "b"
    print(f"{v.len()} {v[2]} {s}")
    v = List.new()
    print(f"{v.len()}")

    var Bag { items, name, n } = make_bag()
    items.push(8)
    name = name ++ "!"
    n += 1
    print(f"{items.len()} {name} {n}")

    var (_, keep) = ("dropped", 1)
    keep += 0
    print(f"{refutable(1) + keep - 1} {refutable(0)}")
