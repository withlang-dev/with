//! expect-stdout: 0 0
//! expect-stdout: 10 10
//! expect-stdout: 20 20
//! expect-stdout: 1 3 5
//! expect-stdout: 0 1 10 11
//! expect-stdout: 121 131 141
//! expect-stdout: 6

// #1471 (§12.4: "`move ||` transfers ownership, which for a Copy value is a
// copy."): a `move` closure created in a loop body copies the Copy local at
// ITS creation. One site makes one closure per iteration, and each keeps
// what it captured — the `for` binding, a fresh `let` in the body, a
// `while` counter, two captures at once, a nested loop, and a Copy struct.
// Before the fix every closure from one site shared a single environment
// slot, so all of them observed the final iteration's value (threads
// spawned in a loop all ran with the last index). A non-move closure would
// hold the iteration's local by place — a view that must not outlive it.

type Pt { x: i32, y: i32 }
impl Copy for Pt

fn keep(v: Vec[fn() -> i32], f: fn() -> i32) -> Vec[fn() -> i32]:
    var w = v
    w.push(f)
    w

fn main:
    var fs: Vec[fn() -> i32] = Vec.new()
    for i in 0..3:
        let n = i
        fs.push(move () => n * 10)
    var gs: Vec[fn() -> i32] = Vec.new()
    var j = 0
    while j < 3:
        gs.push(move () => j * 10)
        j = j + 1
    for k in 0..3:
        print(f"{fs[k]()} {gs[k]()}")

    var hs: Vec[fn() -> i32] = Vec.new()
    for i in 0..3:
        let p = Pt { x: i, y: i + 1 }
        hs.push(move () => p.x + p.y)
    print(f"{hs[0]()} {hs[1]()} {hs[2]()}")

    var ns: Vec[fn() -> i32] = Vec.new()
    for a in 0..2:
        for b in 0..2:
            ns.push(move () => a * 10 + b)
    print(f"{ns[0]()} {ns[1]()} {ns[2]()} {ns[3]()}")

    var ts: Vec[fn(i32) -> i32] = Vec.new()
    let base = 100
    for i in 0..3:
        ts = keep_arg(ts, move (x: i32) => base + i * 10 + x)
    print(f"{ts[0](21)} {ts[1](21)} {ts[2](21)}")

    // A non-escaping closure in a loop still sees each iteration's value.
    var total = 0
    for i in 0..3:
        total = total + run(() => i + 1)
    print(total)

fn keep_arg(v: Vec[fn(i32) -> i32], f: fn(i32) -> i32) -> Vec[fn(i32) -> i32]:
    var w = v
    w.push(f)
    w

fn run(f: fn() -> i32) -> i32: f()
