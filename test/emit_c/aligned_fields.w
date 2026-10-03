//! expect-stdout: sizes 64/32 96/32 128/128
//! expect-stdout: outer offset 64 aligned true
//! expect-stdout: vec aligned 20 sum 190
//! expect-stdout: values 1 2 3 4

// #2022: the C backend emitted `@[align(N)]` records (§16.4) at C's natural
// layout: `struct Al { int8_t a; int64_t b; }` was 16 bytes where TypeLayout
// (and every constant the compiler derives from it) says 64, so `o.al.b`
// sat at offset 16 of Outer instead of 64. The emitted records now carry the
// declared alignment, and _Static_asserts prove each one is TypeLayout's.

type Al { a: i8, @[align(32)] b: i64 }
type Outer { c: u8, al: Al }
type Big { @[align(128)] n: i64 }

fn main:
    print(f"sizes {comptime Al.size()}/{comptime Al.align()} {comptime Outer.size()}/{comptime Outer.align()} {comptime Big.size()}/{comptime Big.align()}")
    let o = Outer { c: 1, al: Al { a: 2, b: 3 } }
    let base = &raw const o as i64
    let b_at = &raw const o.al.b as i64
    print(f"outer offset {b_at - base} aligned {b_at % 32 == 0}")
    var v: Vec[Big] = Vec.new()
    for i in 0..20: v.push(Big { n: i as i64 })
    var ok = 0
    var sum: i64 = 0
    for i in 0..v.len() as i32:
        if (&raw const v[i].n as i64) % 128 == 0: ok += 1
        sum = sum + v[i].n
    print(f"vec aligned {ok} sum {sum}")
    print(f"values {o.c} {o.al.a} {o.al.b} {v.len() / 5}")
