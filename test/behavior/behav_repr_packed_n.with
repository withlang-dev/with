//! expect-stdout: Hdr: size 8 align 2
//! expect-stdout: Outer: size 12 align 2
//! expect-stdout: Wide: size 16 align 4
//! expect-stdout: Loose: size 8 align 4
//! expect-stdout: Tight: size 5 align 1
//! expect-stdout: fields: a=513 b=305419896 c=7 tag=1 tail=9
//! expect-stdout: after writes: b=305419897 big=81985529216486896 d=3
//! expect-stdout: vec: 3 hdrs, b sum=6
//! expect-stdout: by value: 305419897
//! expect-stdout: a within the cap: 513
//! expect-stdout: ok

// Spec §16.4 (D71, #1421): `@[repr(packed(N))]`, N a power of two, caps
// every field's alignment at N — a field whose natural alignment exceeds N
// is placed at alignment N — and the record's alignment is at most N.
// Hdr { a: u16, b: u32, c: u8 } under packed(2): a@0, b@2, c@6, size 8,
// alignment 2; embedded in Outer it lands at 2. Wide { c: u8, big: u64,
// d: u8 } under packed(4): big@4, d@12, size 16, alignment 4. A cap no
// field reaches changes nothing (Loose). `repr(packed)` is alignment 1
// (Tight), which size_of and align_of now agree on. Fields read and write
// through the capped offsets, in a List and by value; a reference to a
// field naturally aligned within the cap is ordinary (`&h.a`).

@[repr(packed(2))]
type Hdr { a: u16, b: u32, c: u8 }

type Outer { tag: u8, h: Hdr, tail: u8 }

@[repr(packed(4))]
type Wide { c: u8, big: u64, d: u8 }

@[repr(packed(8))]
type Loose { a: u8, b: u32 }

@[repr(packed)]
type Tight { a: u8, b: u32 }

fn read_b(h: Hdr) -> u32: h.b

fn main:
    print(f"Hdr: size {size_of[Hdr]()} align {align_of[Hdr]()}")
    print(f"Outer: size {size_of[Outer]()} align {align_of[Outer]()}")
    print(f"Wide: size {size_of[Wide]()} align {align_of[Wide]()}")
    print(f"Loose: size {size_of[Loose]()} align {align_of[Loose]()}")
    print(f"Tight: size {size_of[Tight]()} align {align_of[Tight]()}")
    var o = Outer { tag: 1, h: Hdr { a: 513, b: 0x12345678, c: 7 }, tail: 9 }
    print(f"fields: a={o.h.a} b={o.h.b} c={o.h.c} tag={o.tag} tail={o.tail}")
    o.h.b = o.h.b + 1
    var w = Wide { c: 1, big: 0x0123456789ABCDEF, d: 2 }
    w.big = w.big + 1
    w.d = w.d + 1
    print(f"after writes: b={o.h.b} big={w.big} d={w.d}")
    var hs: List[Hdr] = List.new()
    for i in 1..4: hs.push(Hdr { a: 0, b: i as u32, c: 0 })
    var sum: u32 = 0
    for h in hs: sum = sum + h.b
    print(f"vec: {hs.len()} hdrs, b sum={sum}")
    print(f"by value: {read_b(o.h)}")
    let ra = &o.h.a
    print(f"a within the cap: {ra}")
    print("ok")
