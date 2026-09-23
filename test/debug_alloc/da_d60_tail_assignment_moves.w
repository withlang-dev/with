//! expect-debug-alloc: leak count=0
//! expect-stdout: str hi!
//! expect-stdout: vec 2
//! expect-stdout: struct 2 hi!
//! expect-stdout: option hi!
//! expect-stdout: concat ab!
//! expect-stdout: arms yes! no!
//! expect-stdout: block arm made!
//! expect-stdout: try ok! err
//! expect-stdout: closure fresh!

// §9.1 / D60: the tail assignment yields a read of its place after the
// store, under the ordinary move rules — a whole local of a type that is not
// Copy moves out to the caller, exactly as the tail spelled as the local
// does. The stored value is owned once: the local's scope-exit drop is
// gone, the old value was dropped by the store, and nothing leaks. (#1339's
// arm value was the right-hand side while the local kept it too: a double
// free.)

type Holder { n: i32, name: str }

fn compute(s: &str): s.clone() ++ "!"

fn nums -> Vec[i32]:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v

fn local_str -> str:
    var s = "a".clone()
    s = compute("hi")

fn local_vec -> Vec[i32]:
    var v: Vec[i32] = Vec.new()
    v.push(9)
    v = nums()

fn local_struct -> Holder:
    var h = Holder { n: 1, name: "one".clone() }
    h = Holder { n: 2, name: compute("hi") }

fn local_opt -> Option[str]:
    var o: Option[str] = Some("old".clone())
    o = Some(compute("hi"))

fn local_concat -> str:
    var s = "a".clone()
    s = s ++ compute("b")

fn arms(p: bool) -> str:
    var s = "".clone()
    if p: s = compute("yes") else: s = compute("no")

fn block_arm(p: bool) -> str:
    if p:
        var t = "old".clone()
        t = compute("made")
    else:
        compute("other")

fn parse(ok: bool) -> Result[str, str]:
    if ok: Ok(compute("ok")) else: Err("err".clone())

// An early `?` exit in the stored value still drops the old value.
fn try_store(ok: bool) -> Result[str, str]:
    var s = "old".clone()
    s = parse(ok)?

fn main:
    print(f"str {local_str()}")
    print(f"vec {local_vec().len()}")
    let h = local_struct()
    print(f"struct {h.n} {h.name}")
    let o = local_opt() ?? "none".clone()
    print(f"option {o}")
    print(f"concat {local_concat()}")
    print(f"arms {arms(true)} {arms(false)}")
    print(f"block arm {block_arm(true)}")
    let good = try_store(true) ?? "bad".clone()
    let bad = match try_store(false):
        Ok(v) => v
        Err(e) => e
    print(f"try {good} {bad}")
    let f: fn() -> str = () =>
        var c = "".clone()
        c = compute("fresh")
    print(f"closure {f()}")
