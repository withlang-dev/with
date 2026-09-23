//! expect-debug-alloc: leak count=0
//! expect-stdout: vec keep 3
//! expect-stdout: vec reject none
//! expect-stdout: vec none none
//! expect-stdout: str keep abcdef
//! expect-stdout: str reject none
//! expect-stdout: struct keep pq 2
//! expect-stdout: struct reject none
//! expect-stdout: call keep 3
//! expect-stdout: named keep 3
//! expect-stdout: typed keep 3
//! expect-stdout: i32 keep 10
//! expect-stdout: i32 reject none
//! expect-stdout: ref keep 3
//! expect-stdout: chain 4
//! expect-stdout: saw 3
//! expect-stdout: inspect some 3
//! expect-stdout: inspect none none
//! expect-stdout: ok 3
//! expect-stdout: R inspect ok 3
//! expect-stdout: R inspect err 2
//! expect-stdout: err 2
//! expect-stdout: R inspect_err err 2
//! expect-stdout: R inspect_err ok 3
//! expect-stdout: R context ok 3
//! expect-stdout: R context err
//! expect-stdout: R with_context ok 3
//! expect-stdout: R with_context err

// #1379 (§10.5: `filter | (fn(&T) -> bool) -> Option[T]`): the predicate
// observes the payload; the payload moves once, into the kept `Some`, and a
// rejected payload is dropped once. The predicate used to receive the
// payload by value while the kept `Some` took it again, and the receiver
// temp's enum drop freed it under the result: DOUBLE FREE (Vec, struct),
// a silent second str free.
// Covers: Vec / str / struct / i32 payload × keep / reject / None, a call
// result subject, a named `fn(&T) -> bool` predicate, an explicitly typed
// `(q: &P)` closure, an Option[&T] payload, a filter feeding map, and the
// other observing combinators (Option.inspect, Result.inspect /
// inspect_err / context / with_context) on both paths.

type P { name: str, xs: Vec[i32] }

fn mkv(n: i32) -> Vec[i32]:
    var xs: Vec[i32] = Vec.new()
    for i in 0..n: xs.push(i)
    xs

fn some_vec(n: i32) -> Option[Vec[i32]]: Some(mkv(n))

fn nonempty(v: &Vec[i32]) -> bool: v.len() > 0

fn show_vec(tag: &str, o: &Option[Vec[i32]]):
    match o:
        Some(v) => print(f"{tag} {v.len()}")
        None => print(f"{tag} none")

fn show_str(tag: &str, o: &Option[str]):
    match o:
        Some(s) => print(f"{tag} {s}")
        None => print(f"{tag} none")

fn rvv(ok: bool) -> Result[Vec[i32], Vec[i32]]:
    if ok: return Ok(mkv(3))
    Err(mkv(2))

fn rvs(ok: bool) -> Result[Vec[i32], str]:
    if ok: return Ok(mkv(3))
    Err("bad" ++ "")

fn show_res(tag: &str, r: &Result[Vec[i32], Vec[i32]]):
    match r:
        Ok(v) => print(f"{tag} {v.len()}")
        Err(v) => print(f"{tag} {v.len()}")

fn main:
    let a: Option[Vec[i32]] = Some(mkv(3))
    show_vec("vec keep", &a.filter((v) => v.len() > 0))
    let b: Option[Vec[i32]] = Some(mkv(3))
    show_vec("vec reject", &b.filter((v) => v.len() > 5))
    let c: Option[Vec[i32]] = None
    show_vec("vec none", &c.filter((v) => v.len() > 0))

    let s: Option[str] = Some("abc" ++ "def")
    show_str("str keep", &s.filter((t) => t.len() == 6))
    let s2: Option[str] = Some("abc" ++ "def")
    show_str("str reject", &s2.filter((t) => t.starts_with("z")))

    let p: Option[P] = Some(P { name: "p" ++ "q", xs: mkv(2) })
    match p.filter((q) => q.xs.len() == 2):
        Some(q) => print(f"struct keep {q.name} {q.xs.len()}")
        None => print("struct keep none")
    let p2: Option[P] = Some(P { name: "p" ++ "q", xs: mkv(2) })
    match p2.filter((q) => q.name == "zz"):
        Some(q) => print(f"struct reject {q.name}")
        None => print("struct reject none")

    show_vec("call keep", &some_vec(3).filter((v) => v.len() == 3))
    let n: Option[Vec[i32]] = Some(mkv(3))
    show_vec("named keep", &n.filter(nonempty))
    let t: Option[P] = Some(P { name: "t" ++ "", xs: mkv(3) })
    match t.filter((q: &P) => q.xs.len() == 3):
        Some(q) => print(f"typed keep {q.xs.len()}")
        None => print("typed keep none")

    match Some(10).filter((x) => x > 5):
        Some(x) => print(f"i32 keep {x}")
        None => print("i32 keep none")
    match Some(1).filter((x) => x > 5):
        Some(x) => print(f"i32 reject {x}")
        None => print("i32 reject none")

    let owner = mkv(3)
    let r: Option[&Vec[i32]] = Some(&owner)
    match r.filter((v) => v.len() == 3):
        Some(v) => print(f"ref keep {v.len()}")
        None => print("ref keep none")

    let m: Option[Vec[i32]] = Some(mkv(4))
    print(f"chain {m.filter((v) => v.len() > 1).map((v) => v.len()).unwrap_or(0)}")

    // The other observers decompose their subject the same way: `inspect`
    // sees `&T` and moves the payload into the result, `inspect_err` the
    // Err payload, and `context` / `with_context` move the Ok payload
    // through (the Err payload into the context error). Each was a DOUBLE
    // FREE of the moved payload.
    let io: Option[Vec[i32]] = Some(mkv(3))
    show_vec("inspect some", &io.inspect((v) => print(f"saw {v.len()}")))
    let inone: Option[Vec[i32]] = None
    show_vec("inspect none", &inone.inspect((v) => print(f"saw {v.len()}")))
    show_res("R inspect ok", &rvv(true).inspect((v) => print(f"ok {v.len()}")))
    show_res("R inspect err", &rvv(false).inspect((v) => print(f"ok {v.len()}")))
    show_res("R inspect_err err", &rvv(false).inspect_err((v) => print(f"err {v.len()}")))
    show_res("R inspect_err ok", &rvv(true).inspect_err((v) => print(f"err {v.len()}")))
    match rvs(true).context("reading"):
        Ok(v) => print(f"R context ok {v.len()}")
        Err(_) => print("R context err")
    match rvs(false).context("reading"):
        Ok(v) => print(f"R context ok {v.len()}")
        Err(_) => print("R context err")
    match rvs(true).with_context(() => "w" ++ ""):
        Ok(v) => print(f"R with_context ok {v.len()}")
        Err(_) => print("R with_context err")
    match rvs(false).with_context(() => "w" ++ ""):
        Ok(v) => print(f"R with_context ok {v.len()}")
        Err(_) => print("R with_context err")
