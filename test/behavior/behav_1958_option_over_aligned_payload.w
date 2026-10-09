//! expect-stdout: Option[Al] 96/32 96/32 ok
//! expect-stdout: Option[Option[Al]] 128/32 128/32 ok
//! expect-stdout: Option[V4] 32/16 32/16 ok
//! expect-stdout: Option[V8] ok
//! expect-stdout: some true none false
//! expect-stdout: match 1 2
//! expect-stdout: take 1 2 | empty true
//! expect-stdout: unwrap 1 2
//! expect-stdout: nested 3 4
//! expect-stdout: v4 1.5 2.5 3.5 4.5
//! expect-stdout: v8 7 7 7 7 7 7 7 7 | sum 56
//! expect-stdout: pop 5 6 | 8 8 8 8 8 8 8 8
//! expect-stdout: none none

// #1958: an `Option` whose payload the §3 nullable niche does not cover takes
// §2's `{ tag, [n x unit] }` body from TypeLayout, like every other enum, so
// a payload the model aligns above (an `@[align(N)]` record) or below (a SIMD
// vector LLVM aligns past the target's rule, §4.3d) its LLVM body lands at
// the model's offset. Before: `{ i32, T }` put T at LLVM's alignment, and
// the #1438 model-vs-emitted check refused the program (`BUG: Option
// 'Option[Al]' is emitted as 40 bytes aligned 8, but TypeLayout lays it out
// as 48 bytes aligned 16`). The rows print the model's size/align, then
// LLVM's (recovered from `(i8, T)` as in behav_layout_model_matches_llvm);
// the V8 row prints only the verdict, since `Vector[8, f32]`'s alignment is
// the target's (32 on x86_64, 16 on AArch64).

type Al { a: i8, @[align(32)] b: i64 }
type V4 = Vector[4, f32]
type V8 = Vector[8, f32]
type OAl = Option[Al]
type OOAl = Option[Option[Al]]
type OV4 = Option[V4]
type OV8 = Option[V8]
type W_OAl = (i8, OAl)
type W_OOAl = (i8, OOAl)
type W_OV4 = (i8, OV4)
type W_OV8 = (i8, OV8)

fn llvm_align(size: i64, pair: i64) -> i64:
    for a in [1, 2, 4, 8, 16, 32, 64]:
        let up = if (a + size) % a == 0: a + size else: a + size + (a - (a + size) % a)
        if up == pair: return a
    -1

fn row(name: str, ms: usize, ma: usize, ls: i64, pair: i64):
    let la = llvm_align(ls, pair)
    let mark = if ms as i64 == ls and ma as i64 == la: "ok" else: "MISMATCH"
    print(f"{name} {ms}/{ma} {ls}/{la} {mark}")

fn verdict(name: str, ms: usize, ma: usize, ls: i64, pair: i64):
    let la = llvm_align(ls, pair)
    let mark = if ms as i64 == ls and ma as i64 == la: "ok" else: f"MISMATCH {ms}/{ma} {ls}/{la}"
    print(f"{name} {mark}")

fn make(a: i8, b: i64) -> Option[Al]: Some(Al { a: a, b: b })

fn lanes8(v: V8) -> str: f"{v[0]} {v[1]} {v[2]} {v[3]} {v[4]} {v[5]} {v[6]} {v[7]}"

fn main:
    row("Option[Al]", comptime OAl.size(), comptime OAl.align(), size_of[OAl](), size_of[W_OAl]())
    row("Option[Option[Al]]", comptime OOAl.size(), comptime OOAl.align(), size_of[OOAl](), size_of[W_OOAl]())
    row("Option[V4]", comptime OV4.size(), comptime OV4.align(), size_of[OV4](), size_of[W_OV4]())
    verdict("Option[V8]", comptime OV8.size(), comptime OV8.align(), size_of[OV8](), size_of[W_OV8]())

    var o = make(1, 2)
    let n: Option[Al] = None
    print(f"some {o.is_some()} none {n.is_some()}")
    match make(1, 2):
        .Some(v) => print(f"match {v.a} {v.b}")
        .None => print("match none")
    let t = o
    o = None
    match t:
        .Some(v) => print(f"take {v.a} {v.b} | empty {o.is_none()}")
        .None => print("take none")
    let u = make(1, 2).unwrap()
    print(f"unwrap {u.a} {u.b}")

    let nested: Option[Option[Al]] = Some(make(3, 4))
    match nested:
        .Some(inner) =>
            match inner:
                .Some(v) => print(f"nested {v.a} {v.b}")
                .None => print("nested inner none")
        .None => print("nested none")

    let v4: Option[V4] = Some(V4(1.5, 2.5, 3.5, 4.5))
    let w4 = v4.unwrap()
    print(f"v4 {w4[0]} {w4[1]} {w4[2]} {w4[3]}")
    let v8: Option[V8] = Some(V8.splat(7))
    var sum: f32 = 0
    match v8:
        .Some(w) =>
            for i in 0..8: sum = sum + w[i]
            print(f"v8 {lanes8(w)} | sum {sum}")
        .None => print("v8 none")

    var als: List[Al] = List.new()
    als.push(Al { a: 5, b: 6 })
    var vs: List[V8] = List.new()
    vs.push(V8.splat(8))
    let pa = als.pop().unwrap()
    let pv = vs.pop().unwrap()
    print(f"pop {pa.a} {pa.b} | {lanes8(pv)}")
    let na = als.pop()
    let nv = vs.pop()
    print(f"{if na.is_none(): "none" else: "some"} {if nv.is_none(): "none" else: "some"}")
