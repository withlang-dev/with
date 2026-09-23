//! expect-debug-alloc: leak count=0
//! expect-stdout: uo R str 12 ok
//! expect-stdout: uo O str 12 ok
//! expect-stdout: uo R vec 3 ok
//! expect-stdout: uo O vec 3 ok
//! expect-stdout: uo R struct payload 3 ok
//! expect-stdout: uo O struct payload 3 ok
//! expect-stdout: uo call str 12 ok
//! expect-stdout: uo field str 12 ok
//! expect-stdout: uo err own dflt! ok
//! expect-stdout: uo none own 1 ok
//! expect-stdout: uoe R str 12 ok
//! expect-stdout: uoe O vec 3 ok
//! expect-stdout: uoe R struct payload 3 ok
//! expect-stdout: uoe err own dflt! ok
//! expect-stdout: dq R vec 3 ok
//! expect-stdout: dq O struct payload 3 ok
//! expect-stdout: dq ok own-unused 1 ok
//! expect-stdout: dq err own dflt! ok
//! expect-stdout: flatten vec 3 ok

// #1363: unwrap_or, unwrap_or_else and `??` move the payload out of the
// materialized subject on the success path; the subject's scope-exit drop
// (the enum's variant-aware glue) then freed the payload the result owned —
// `read_file(p).unwrap_or("")` returned a str over a freed buffer (garbage
// small, SIGSEGV past the munmap threshold). A Vec or struct payload was a
// DOUBLE FREE here; a str one was silent until the str free path consulted
// the ledger. The owned default is lazy (§10): on the success path it is
// never taken and must still be freed once (`o ?? d` leaked it).
// Covers: each eliminator × Result/Option × str/Vec/struct payload, the
// subject a local, a call result and a field moved out, the success and the
// failure path with an owned default, and Option.flatten (same class).
use std.fs

type P { name: str, xs: Vec[i32] }
type HS { v: Result[str, IoError] }

fn mkv(n: i32) -> Vec[i32]:
    var xs: Vec[i32] = Vec.new()
    for i in 0..n: xs.push(i)
    xs

fn rs(ok: bool) -> Result[str, str]:
    if not ok: return Err("no" ++ "pe")
    Ok("payload-" ++ "text")

fn os(ok: bool) -> Option[str]:
    if not ok: return None
    Some("payload-" ++ "text")

fn rv(ok: bool) -> Result[Vec[i32], str]:
    if not ok: return Err("no" ++ "pe")
    Ok(mkv(3))

fn ov(ok: bool) -> Option[Vec[i32]]:
    if not ok: return None
    Some(mkv(3))

fn rp(ok: bool) -> Result[P, str]:
    if not ok: return Err("no" ++ "pe")
    Ok(P { name: "payload" ++ "", xs: mkv(3) })

fn op(ok: bool) -> Option[P]:
    if not ok: return None
    Some(P { name: "payload" ++ "", xs: mkv(3) })

fn say_s(tag: &str, t: &str): print(f"{tag} {t.len()} ok")
fn say_v(tag: &str, t: &Vec[i32]): print(f"{tag} {t.len()} ok")
fn say_p(tag: &str, t: &P): print(f"{tag} {t.name} {t.xs.len()} ok")

fn main:
    let path = "out/tmp/da_carrier_eliminator_payload_owned.txt"
    let _mk = mkdir_p("out/tmp")
    let _w = write_file(path, "file content")

    let r1 = rs(true)
    say_s("uo R str", &r1.unwrap_or(""))
    let o1 = os(true)
    say_s("uo O str", &o1.unwrap_or(""))
    let r2 = rv(true)
    let v2 = r2.unwrap_or(Vec.new())
    say_v("uo R vec", &v2)
    let o2 = ov(true)
    let w2 = o2.unwrap_or(Vec.new())
    say_v("uo O vec", &w2)
    let r3 = rp(true)
    say_p("uo R struct", &r3.unwrap_or(P { name: "", xs: Vec.new() }))
    let o3 = op(true)
    say_p("uo O struct", &o3.unwrap_or(P { name: "", xs: Vec.new() }))
    say_s("uo call str", &read_file(path).unwrap_or(""))
    var h = HS { v: read_file(path) }
    say_s("uo field str", &(move h.v).unwrap_or(""))
    let d1 = "dflt" ++ "!"
    let t1 = rs(false).unwrap_or(d1)
    print(f"uo err own {t1} ok")
    var d2: Vec[i32] = Vec.new()
    d2.push(7)
    let t2 = ov(false).unwrap_or(d2)
    print(f"uo none own {t2.len()} ok")

    let r4 = rs(true)
    say_s("uoe R str", &r4.unwrap_or_else((_) => ""))
    let o4 = ov(true)
    let d3: Vec[i32] = Vec.new()
    say_v("uoe O vec", &o4.unwrap_or_else(() => d3))
    let r5 = rp(true)
    say_p("uoe R struct", &r5.unwrap_or_else((_) => P { name: "", xs: Vec.new() }))
    let d4 = "dflt" ++ "!"
    let t4 = rs(false).unwrap_or_else((_) => d4)
    print(f"uoe err own {t4} ok")

    let r6 = rv(true)
    let v6 = r6 ?? Vec.new()
    say_v("dq R vec", &v6)
    let o6 = op(true)
    say_p("dq O struct", &(o6 ?? P { name: "", xs: Vec.new() }))
    var d5: Vec[i32] = Vec.new()
    d5.push(7)
    let t5 = ov(true) ?? d5
    print(f"dq ok own-unused {t5.len() / 3} ok")
    let d6 = "dflt" ++ "!"
    let t6 = rs(false) ?? d6
    print(f"dq err own {t6} ok")

    let nested: Option[Option[Vec[i32]]] = Some(ov(true))
    let flat = nested.flatten()
    let vf = flat.unwrap_or(Vec.new())
    say_v("flatten vec", &vf)
    let _rm = remove_file(path)
