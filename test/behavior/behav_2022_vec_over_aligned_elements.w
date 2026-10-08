//! expect-stdout: Al 64/32 aligned 40 sum 780
//! expect-stdout: Big 128/128 aligned 20 sum 190
//! expect-stdout: capacity aligned 5
//! expect-stdout: drop aligned 12 hello11

// #2022: a Vec of an over-aligned element (§16.4 `@[align(N)]`) keeps every
// element at an N-aligned address. The runtime's buffers were the
// allocator's 16-aligned payloads, so `v[1].b` of a Vec[Al] sat at 16 mod 32.
// Each Vec grows past several reallocations (8, 16, 32 elements).

type Al { a: i8, @[align(32)] b: i64 }
type Big { @[align(128)] n: i64 }
type Named { @[align(64)] s: str, k: i64 }

fn count_aligned_al(v: &Vec[Al]) -> i32:
    var ok = 0
    for i in 0..v.len() as i32:
        if (&raw const v[i].b as i64) % 32 == 0: ok += 1
    ok

fn main:
    var v: Vec[Al] = Vec.new()
    for i in 0..40: v.push(Al { a: 1, b: i as i64 })
    var sum: i64 = 0
    for x in v: sum = sum + x.b
    print(f"Al {comptime Al.size()}/{comptime Al.align()} aligned {count_aligned_al(&v)} sum {sum}")

    var big: Vec[Big] = Vec.new()
    for i in 0..20: big.push(Big { n: i as i64 })
    var big_ok = 0
    var big_sum: i64 = 0
    for i in 0..big.len() as i32:
        if (&raw const big[i].n as i64) % 128 == 0: big_ok += 1
        big_sum = big_sum + big[i].n
    print(f"Big {comptime Big.size()}/{comptime Big.align()} aligned {big_ok} sum {big_sum}")

    var reserved: Vec[Al] = Vec.with_capacity(5)
    for i in 0..5: reserved.push(Al { a: 2, b: i as i64 })
    print(f"capacity aligned {count_aligned_al(&reserved)}")

    var named: Vec[Named] = Vec.new()
    for i in 0..12: named.push(Named { s: "hello" ++ f"{i}", k: i as i64 })
    var named_ok = 0
    for i in 0..named.len() as i32:
        if (&raw const named[i].s as i64) % 64 == 0: named_ok += 1
    print(f"drop aligned {named_ok} {named[11].s}")
