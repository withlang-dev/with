//! expect-debug-alloc: leak count=0
//! expect-stdout: a 1 b 2 c 1
//! expect-stdout: a.name x b.name y
//! expect-stdout: ok

// D120 stage 3: three holders of one struct of values (a str and a List of
// str), one of them written after the copy. Each shared buffer is freed
// once, by its last holder; a copy retains every field it shares, so each
// is released exactly as many times as it was held.
use std.box.Box

type Rec { name: str, tags: List[str], n: i32 }

unsafe fn raw_roundtrip(p: *mut Rec):
    var r = *p
    r.tags.push("z")
    *p = move r

fn main:
    var a = Rec { name: "x", tags: ["t"], n: 1 }
    var b = a
    var c = a
    b.tags.push("u")
    b.name = "y"
    c.n = 3
    let boxed = Box.new(Rec { name: "b" ++ "ox", tags: ["q"], n: 4 })
    drop(boxed)
    var unboxed = Box.new(Rec { name: "i" ++ "n", tags: ["r"], n: 5 }).into_inner()
    unsafe { raw_roundtrip(&raw mut unboxed as *mut Rec) }
    print(f"a {a.tags.len()} b {b.tags.len()} c {c.tags.len()}")
    print(f"a.name {a.name} b.name {b.name}")
    print(f"{a.n == 1 and c.n == 3 and unboxed.tags.len() == 2}".replace("true", "ok"))
