//! expect-stdout: ok

// #595: a generic fn whose param nests the type param inside another generic
// (Vec[Task[T]], Pair[Vec[T]]) must bind T structurally at codegen
// monomorphization — positional binding mis-bound T to the OUTER arg
// (T <- Task[i32]) and crashed codegen with no diagnostic (§11 generics).

type Pair[T] { a: T, b: T }
type Duo[A, B] { pending_a: A, anchor_a: A, pending_b: B, anchor_b: B }

fn sum_pairs[T](items: Vec[Pair[T]]) -> i32:
    var s = 0
    for p in &items:
        s = s + 1
    s

fn first_len[T](wrapped: Pair[Vec[T]]) -> i64:
    wrapped.a.len()

fn cleanup_remaining[T](tasks: Vec[Task[T]], start: i32):
    let total = tasks.len() as i32
    var i = start
    while i < total:
        tasks[i].join_cleanup()
        i = i + 1

async fn child() -> i32:
    1

async fn main_task -> i32:
    let tasks: Vec[Task[i32]] = Vec.new()
    tasks.push(child())
    cleanup_remaining(tasks, 0)
    0

fn main:
    let ps: Vec[Pair[i32]] = Vec.new()
    ps.push(Pair { a: 1, b: 2 })
    ps.push(Pair { a: 3, b: 4 })
    assert(sum_pairs(ps) == 2)
    let v: Vec[i64] = Vec.new()
    v.push(9)
    let w = Pair { a: v, b: Vec.new() }
    assert(first_len(w) == 1)
    let v2: Vec[i64] = Vec.new()
    v2.push(10)
    let w2 = Pair { b: Vec.new(), a: v2 }
    assert(first_len(w2) == 1)
    let v3: Vec[i64] = Vec.new()
    v3.push(12)
    let w3 = Pair { b: (Vec.new()), a: v3 }
    assert(first_len(w3) == 1)
    let pending = Vec.new()
    let v4: Vec[i64] = Vec.new()
    v4.push(13)
    let w4 = Pair { b: pending, a: v4 }
    assert(first_len(w4) == 1)
    let va: Vec[i64] = Vec.new()
    va.push(11)
    let vb: HashSet[str] = HashSet.new()
    vb.insert("x")
    let d = Duo {
        pending_a: Vec.new(),
        anchor_a: va,
        pending_b: HashSet.new(),
        anchor_b: vb,
    }
    assert(d.pending_a.len() == 0)
    assert(not d.pending_b.contains("x"))
    let _ = main_task().await
    print("ok")
