//! expect-stdout: 2000000 abcdefgh ok
//! expect-stdout: 2000000 abcdefgh ok
//! expect-stdout: 2000000 abcdefgh ok
//! expect-stdout: 0 ok
//! expect-stdout: 500000 ok

// #1363: `read_file(p).unwrap_or("")` returned a str with the payload's length
// over a freed data pointer — the materialized Result's scope-exit drop freed
// the payload the result owned. Past the allocator's large threshold the
// buffer is unmapped, so reading it faulted (SIGSEGV); a small one read
// garbage. unwrap_or_else and `??` take the same path; a Vec payload too.
use std.fs

fn chunk(): "abcdefgh" ++ ""

fn check(t: &str):
    var sum: i64 = 0
    for i in 0..t.len(): sum = sum + t[i] as i64
    // every 8-byte chunk sums to 804
    let ok = sum == t.len() / 8 * 804
    let head = t.slice(0, 8)
    let verdict = if ok: "ok" else: "BAD"
    print(f"{t.len()} {head} {verdict}")

fn main:
    let path = "out/tmp/behav_unwrap_or_large_str_payload.txt"
    let _mk = mkdir_p("out/tmp")
    var piece = ""
    for i in 0..200: piece = piece ++ chunk()
    var big = ""
    for i in 0..1250: big = big ++ piece
    let _w = write_file(path, big)

    let t = read_file(path).unwrap_or("")
    check(&t)
    let u = read_file(path).unwrap_or_else((_) => "")
    check(&u)
    let v = read_file(path) ?? ""
    check(&v)
    let missing = read_file("out/tmp/behav_unwrap_or_large_str_payload.missing").unwrap_or("")
    print(f"{missing.len()} ok")

    var xs: Vec[i32] = Vec.new()
    for i in 0..500000: xs.push(i)
    let o: Option[Vec[i32]] = Some(xs)
    let w = o.unwrap_or(Vec.new())
    print(f"{w.len()} ok")
    let _rm = remove_file(path)
