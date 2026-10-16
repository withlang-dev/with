//! expect-debug-alloc: leak count=0
//! expect-stdout: a 1 b 2 c 1
//! expect-stdout: a.name x b.name y
//! expect-stdout: ok

// D120 stage 3: three holders of one struct of values (a str and a List of
// str), one of them written after the copy. Each shared buffer is freed
// once, by its last holder; a copy retains every field it shares, so each
// is released exactly as many times as it was held.
type Rec { name: str, tags: List[str], n: i32 }

fn main:
    var a = Rec { name: "x", tags: ["t"], n: 1 }
    var b = a
    var c = a
    b.tags.push("u")
    b.name = "y"
    c.n = 3
    print(f"a {a.tags.len()} b {b.tags.len()} c {c.tags.len()}")
    print(f"a.name {a.name} b.name {b.name}")
    print(f"{a.n == 1 and c.n == 3}".replace("true", "ok"))
