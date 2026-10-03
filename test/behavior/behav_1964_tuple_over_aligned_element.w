//! expect-stdout: (i8,Al) 96/32 96/32 ok
//! expect-stdout: (Al,str) 96/32 96/32 ok
//! expect-stdout: (i8,V4) 32/16 32/16 ok
//! expect-stdout: (i8,V8) ok
//! expect-stdout: fields 1 2 3
//! expect-stdout: destructure 1 2 3
//! expect-stdout: pass 1 2 3 | ret 4 5 6
//! expect-stdout: set 9 10 11
//! expect-stdout: nested 7 1 2 3
//! expect-stdout: match 1 2 3
//! expect-stdout: eq true false
//! expect-stdout: drop hello 8 9
//! expect-stdout: pop 3 4 5 | empty true
//! expect-stdout: some 1 2 3
//! expect-stdout: enumerate 0 1 10
//! expect-stdout: enumerate 1 2 20
//! expect-stdout: zip 1 10 3 30
//! expect-stdout: zip 2 20 4 40
//! expect-stdout: iter 7 5 6
//! expect-stdout: iter 8 9 10
//! expect-stdout: v8 2 7 7 7 7 7 7 7 7 | sum 56
//! expect-stdout: v8 set 3 1 1 1 1 1 1 1 1

// #1964: a tuple places each element where TypeLayout says — at the model's
// alignment for it — not where LLVM's literal struct of the element types
// would. An `@[align(N)]` record's LLVM body is packed (LLVM alignment 1,
// §16.4) and `Vector[8, f32]` is LLVM-aligned 32 where §4.3d caps AArch64 at
// 16, so before the fix `(i8, Al)` was emitted as 72 bytes aligned 8 against
// the model's 96/32, and `(i8, V8)` as 64/32 against 48/16. The rows print
// the model's size/align and LLVM's (alignment recovered from `(i8, T)`, as
// in behav_layout_model_matches_llvm); the V8 row prints only the verdict,
// since the vector's alignment is the target's. The rest constructs,
// projects, destructures, passes, returns, compares, matches, drops and
// moves such tuples through every path that indexes a tuple's elements.

type Al { a: i8, @[align(32)] b: i64 }
type V4 = Vector[4, f32]
type V8 = Vector[8, f32]
type TAl = (i8, Al)
type TAlStr = (Al, str)
type TV4 = (i8, V4)
type TV8 = (i8, V8)
type W_TAl = (i8, TAl)
type W_TAlStr = (i8, TAlStr)
type W_TV4 = (i8, TV4)
type W_TV8 = (i8, TV8)

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

fn make(k: i8, a: i8, b: i64) -> (i8, Al): (k, Al { a: a, b: b })

fn show(t: &(i8, Al)): f"{t.0} {t.1.a} {t.1.b}"

// An iterator of `Al`, so the std adapters build `(i64, Al)` and `(Al, Al)`.
type Als { n: i8, limit: i8 }

impl Iter[Al] for Als:
    mut fn next() -> Option[Al]:
        if self.n >= self.limit:
            return None
        self.n += 1
        Some(Al { a: self.n, b: self.n as i64 * 10 })

fn als(n: i8): Als { n: n, limit: n + 2 }

fn lanes8(v: V8) -> str: f"{v[0]} {v[1]} {v[2]} {v[3]} {v[4]} {v[5]} {v[6]} {v[7]}"

fn main:
    row("(i8,Al)", comptime TAl.size(), comptime TAl.align(), size_of[TAl](), size_of[W_TAl]())
    row("(Al,str)", comptime TAlStr.size(), comptime TAlStr.align(), size_of[TAlStr](), size_of[W_TAlStr]())
    row("(i8,V4)", comptime TV4.size(), comptime TV4.align(), size_of[TV4](), size_of[W_TV4]())
    verdict("(i8,V8)", comptime TV8.size(), comptime TV8.align(), size_of[TV8](), size_of[W_TV8]())

    let t: (i8, Al) = (1, Al { a: 2, b: 3 })
    print(f"fields {t.0} {t.1.a} {t.1.b}")
    let (k, al) = make(1, 2, 3)
    print(f"destructure {k} {al.a} {al.b}")
    let r = make(4, 5, 6)
    print(f"pass {show(&t)} | ret {show(&r)}")

    var m = make(0, 0, 0)
    m.0 = 9
    m.1.a = 10
    m.1.b = 11
    print(f"set {m.0} {m.1.a} {m.1.b}")

    let nested: (i8, (i8, Al)) = (7, t)
    print(f"nested {nested.0} {nested.1.0} {nested.1.1.a} {nested.1.1.b}")

    match make(1, 2, 3):
        (x, y) => print(f"match {x} {y.a} {y.b}")

    let p = make(1, 2, 3)
    let q = make(1, 2, 3)
    let s = make(1, 2, 4)
    print(f"eq {p == q} {p == s}")

    let d: (Al, str) = (Al { a: 8, b: 9 }, "hello".clone())
    let (da, ds) = d
    print(f"drop {ds} {da.a} {da.b}")

    var ts: Vec[(i8, Al)] = Vec.new()
    ts.push(make(3, 4, 5))
    let popped = ts.pop().unwrap()
    print(f"pop {show(&popped)} | empty {ts.pop().is_none()}")

    let o: Option[(i8, Al)] = Some(make(1, 2, 3))
    match o:
        .Some(v) => print(f"some {show(&v)}")
        .None => print("none")

    for (i, v) in als(0).enumerate():
        print(f"enumerate {i} {v.a} {v.b}")
    for (x, y) in als(0).zip(als(2)):
        print(f"zip {x.a} {x.b} {y.a} {y.b}")
    var ps: Vec[(i8, Al)] = Vec.new()
    ps.push(make(7, 5, 6))
    ps.push(make(8, 9, 10))
    for e in ps:
        print(f"iter {show(&e)}")

    let tv: (i8, V8) = (2, V8.splat(7))
    var sum: f32 = 0
    for i in 0..8: sum = sum + tv.1[i]
    print(f"v8 {tv.0} {lanes8(tv.1)} | sum {sum}")
    var mv: (i8, V8) = (0, V8.splat(0))
    mv.0 = 3
    mv.1 = V8.splat(1)
    print(f"v8 set {mv.0} {lanes8(mv.1)}")
