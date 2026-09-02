//! expect-stdout: ok

// #925: the element view from `for x in vec.iter()` must reach a `&T`
// parameter intact for every element shape — str and Vec are the by-value
// pair ABIs where a pointer-to-the-binding read as {ptr,len} shows up as
// garbage; a plain struct and a Copy scalar pass by pointer/value and only
// pin that the fix did not disturb them. Every access form that yields the
// same view (bare `for`, `.get`, `[i]`) must agree with `.iter()`.
type Pair { a: i64, b: i64 }
fn peek_str(s: &str) -> i64: s.len()
fn peek_vec(v: &Vec[i32]) -> i64: v.len() as i64
fn peek_pair(p: &Pair) -> i64: p.a + p.b
fn peek_i32(x: &i32) -> i64: *x as i64

fn main:
    var ss: Vec[str] = Vec.new()
    ss.push("hello")
    for s in ss.iter():
        if peek_str(s) != 5:
            print("FAIL str iter->fn")
            return
        if s.len() != 5:
            print("FAIL str iter method")
            return
    for s in ss:
        if peek_str(s) != 5:
            print("FAIL str bare->fn")
            return
    if peek_str(ss.get(0)) != 5 or peek_str(ss[0]) != 5:
        print("FAIL str get/index->fn")
        return
    var vs: Vec[Vec[i32]] = Vec.new()
    var inner: Vec[i32] = Vec.new()
    inner.push(1)
    inner.push(2)
    vs.push(move inner)
    for v in vs.iter():
        if peek_vec(v) != 2 or v.len() != 2:
            print("FAIL vec iter")
            return
    for v in vs:
        if peek_vec(v) != 2:
            print("FAIL vec bare->fn")
            return
    var ps: Vec[Pair] = Vec.new()
    ps.push(Pair { a: 3, b: 4 })
    for p in ps.iter():
        if peek_pair(p) != 7 or p.a + p.b != 7:
            print("FAIL pair iter")
            return
    var is: Vec[i32] = Vec.new()
    is.push(9)
    for i in is.iter():
        if peek_i32(i) != 9:
            print("FAIL i32 iter->fn")
            return
    print("ok")
