//! expect-stdout: u8 10 red 9 1 100 5 0
//! expect-stdout: u8 20 blue 9 2 200 6 0
//! expect-stdout: u8 30 hi 3 3 300 7 1
//! expect-stdout: u8 40 top 9 4 400 8 0
//! expect-stdout: i8 10 red 9 1 100 5 0
//! expect-stdout: i8 20 blue 9 2 200 6 0
//! expect-stdout: i8 30 hi 3 3 300 7 1
//! expect-stdout: i8 40 top 9 4 400 8 0
//! expect-stdout: u16 10 red 9 1 100 5 0
//! expect-stdout: u16 20 blue 9 2 200 6 0
//! expect-stdout: u16 30 hi 3 3 300 7 1
//! expect-stdout: u16 40 top 9 4 400 8 0
//! expect-stdout: i16 10 red 9 1 100 5 0
//! expect-stdout: i16 20 blue 9 2 200 6 0
//! expect-stdout: i16 30 hi 3 3 300 7 1
//! expect-stdout: i16 40 top 9 4 400 8 0
//! expect-stdout: u32 10 red 9 1 100 5 0
//! expect-stdout: u32 20 blue 9 2 200 6 0
//! expect-stdout: u32 30 hi 3 3 300 7 1
//! expect-stdout: u32 40 top 9 4 400 8 0
//! expect-stdout: i32 10 red 9 1 100 5 0
//! expect-stdout: i32 20 blue 9 2 200 6 0
//! expect-stdout: i32 30 hi 3 3 300 7 1
//! expect-stdout: i32 40 top 9 4 400 8 0
//! expect-stdout: u64 10 red 9 1 100 5 0
//! expect-stdout: u64 20 blue 9 2 200 6 0
//! expect-stdout: u64 30 hi 3 3 300 7 1
//! expect-stdout: u64 40 top 9 4 400 8 0
//! expect-stdout: i64 10 red 9 1 100 5 0
//! expect-stdout: i64 20 blue 9 2 200 6 0
//! expect-stdout: i64 30 hi 3 3 300 7 1
//! expect-stdout: i64 40 top 9 4 400 8 0

// #1444 (§4.4a): a match on a discriminant enum of every repr type picks
// the variant's arm, for values at and above the sign bit of narrow reprs
// (u8 200/255, u16 40000/65535). MirLower typed every discriminant as an
// i32 temp and codegen sized that temp's slot from the loaded u8, so the
// i32 store overflowed it and the match read garbage (u8 printed `10 10`).
// Values beyond i32 are #1451.

enum KU8: u8:
    Red = 1
    Blue = 2
    Hi = 200
    Top = 255

impl Copy for KU8

type HolderU8 { k: KU8 }

fn short_u8(k: KU8) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_u8(k: KU8) -> str:
    match k:
        KU8.Red => "red"
        KU8.Blue => "blue"
        KU8.Hi => "hi"
        KU8.Top => "top"

fn wild_u8(k: KU8) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_u8(k: &KU8) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_u8(k: KU8) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_u8(h: &HolderU8) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_u8():
    for k in [KU8.Red, KU8.Blue, KU8.Hi, KU8.Top]:
        let h = HolderU8 { k }
        let eq = if k == KU8.Hi: 1 else: 0
        print(f"u8 {short_u8(k)} {named_u8(k)} {wild_u8(k)} {by_ref_u8(&k)} {stmt_u8(k)} {field_u8(&h)} {eq}")

enum KI8: i8:
    Red = 1
    Blue = 2
    Hi = 100
    Top = 127

impl Copy for KI8

type HolderI8 { k: KI8 }

fn short_i8(k: KI8) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_i8(k: KI8) -> str:
    match k:
        KI8.Red => "red"
        KI8.Blue => "blue"
        KI8.Hi => "hi"
        KI8.Top => "top"

fn wild_i8(k: KI8) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_i8(k: &KI8) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_i8(k: KI8) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_i8(h: &HolderI8) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_i8():
    for k in [KI8.Red, KI8.Blue, KI8.Hi, KI8.Top]:
        let h = HolderI8 { k }
        let eq = if k == KI8.Hi: 1 else: 0
        print(f"i8 {short_i8(k)} {named_i8(k)} {wild_i8(k)} {by_ref_i8(&k)} {stmt_i8(k)} {field_i8(&h)} {eq}")

enum KU16: u16:
    Red = 1
    Blue = 2
    Hi = 40000
    Top = 65535

impl Copy for KU16

type HolderU16 { k: KU16 }

fn short_u16(k: KU16) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_u16(k: KU16) -> str:
    match k:
        KU16.Red => "red"
        KU16.Blue => "blue"
        KU16.Hi => "hi"
        KU16.Top => "top"

fn wild_u16(k: KU16) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_u16(k: &KU16) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_u16(k: KU16) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_u16(h: &HolderU16) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_u16():
    for k in [KU16.Red, KU16.Blue, KU16.Hi, KU16.Top]:
        let h = HolderU16 { k }
        let eq = if k == KU16.Hi: 1 else: 0
        print(f"u16 {short_u16(k)} {named_u16(k)} {wild_u16(k)} {by_ref_u16(&k)} {stmt_u16(k)} {field_u16(&h)} {eq}")

enum KI16: i16:
    Red = 1
    Blue = 2
    Hi = 30000
    Top = 32767

impl Copy for KI16

type HolderI16 { k: KI16 }

fn short_i16(k: KI16) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_i16(k: KI16) -> str:
    match k:
        KI16.Red => "red"
        KI16.Blue => "blue"
        KI16.Hi => "hi"
        KI16.Top => "top"

fn wild_i16(k: KI16) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_i16(k: &KI16) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_i16(k: KI16) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_i16(h: &HolderI16) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_i16():
    for k in [KI16.Red, KI16.Blue, KI16.Hi, KI16.Top]:
        let h = HolderI16 { k }
        let eq = if k == KI16.Hi: 1 else: 0
        print(f"i16 {short_i16(k)} {named_i16(k)} {wild_i16(k)} {by_ref_i16(&k)} {stmt_i16(k)} {field_i16(&h)} {eq}")

enum KU32: u32:
    Red = 1
    Blue = 2
    Hi = 70000
    Top = 2147483646

impl Copy for KU32

type HolderU32 { k: KU32 }

fn short_u32(k: KU32) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_u32(k: KU32) -> str:
    match k:
        KU32.Red => "red"
        KU32.Blue => "blue"
        KU32.Hi => "hi"
        KU32.Top => "top"

fn wild_u32(k: KU32) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_u32(k: &KU32) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_u32(k: KU32) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_u32(h: &HolderU32) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_u32():
    for k in [KU32.Red, KU32.Blue, KU32.Hi, KU32.Top]:
        let h = HolderU32 { k }
        let eq = if k == KU32.Hi: 1 else: 0
        print(f"u32 {short_u32(k)} {named_u32(k)} {wild_u32(k)} {by_ref_u32(&k)} {stmt_u32(k)} {field_u32(&h)} {eq}")

enum KI32: i32:
    Red = 1
    Blue = 2
    Hi = 5000
    Top = 2147483646

impl Copy for KI32

type HolderI32 { k: KI32 }

fn short_i32(k: KI32) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_i32(k: KI32) -> str:
    match k:
        KI32.Red => "red"
        KI32.Blue => "blue"
        KI32.Hi => "hi"
        KI32.Top => "top"

fn wild_i32(k: KI32) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_i32(k: &KI32) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_i32(k: KI32) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_i32(h: &HolderI32) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_i32():
    for k in [KI32.Red, KI32.Blue, KI32.Hi, KI32.Top]:
        let h = HolderI32 { k }
        let eq = if k == KI32.Hi: 1 else: 0
        print(f"i32 {short_i32(k)} {named_i32(k)} {wild_i32(k)} {by_ref_i32(&k)} {stmt_i32(k)} {field_i32(&h)} {eq}")

enum KU64: u64:
    Red = 1
    Blue = 2
    Hi = 70000
    Top = 2147483646

impl Copy for KU64

type HolderU64 { k: KU64 }

fn short_u64(k: KU64) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_u64(k: KU64) -> str:
    match k:
        KU64.Red => "red"
        KU64.Blue => "blue"
        KU64.Hi => "hi"
        KU64.Top => "top"

fn wild_u64(k: KU64) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_u64(k: &KU64) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_u64(k: KU64) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_u64(h: &HolderU64) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_u64():
    for k in [KU64.Red, KU64.Blue, KU64.Hi, KU64.Top]:
        let h = HolderU64 { k }
        let eq = if k == KU64.Hi: 1 else: 0
        print(f"u64 {short_u64(k)} {named_u64(k)} {wild_u64(k)} {by_ref_u64(&k)} {stmt_u64(k)} {field_u64(&h)} {eq}")

enum KI64: i64:
    Red = 1
    Blue = 2
    Hi = 70000
    Top = 2147483646

impl Copy for KI64

type HolderI64 { k: KI64 }

fn short_i64(k: KI64) -> i32:
    match k:
        .Red => 10
        .Blue => 20
        .Hi => 30
        .Top => 40

fn named_i64(k: KI64) -> str:
    match k:
        KI64.Red => "red"
        KI64.Blue => "blue"
        KI64.Hi => "hi"
        KI64.Top => "top"

fn wild_i64(k: KI64) -> i32:
    match k:
        .Hi => 3
        _ => 9

fn by_ref_i64(k: &KI64) -> i32:
    match k:
        .Red => 1
        .Blue => 2
        .Hi => 3
        .Top => 4

fn stmt_i64(k: KI64) -> i32:
    var out = 0
    match k:
        .Red => out = 100
        .Blue => out = 200
        .Hi => out = 300
        .Top => out = 400
    out

fn field_i64(h: &HolderI64) -> i32:
    match h.k:
        .Red => 5
        .Blue => 6
        .Hi => 7
        .Top => 8

fn run_i64():
    for k in [KI64.Red, KI64.Blue, KI64.Hi, KI64.Top]:
        let h = HolderI64 { k }
        let eq = if k == KI64.Hi: 1 else: 0
        print(f"i64 {short_i64(k)} {named_i64(k)} {wild_i64(k)} {by_ref_i64(&k)} {stmt_i64(k)} {field_i64(&h)} {eq}")

fn main:
    run_u8()
    run_i8()
    run_u16()
    run_i16()
    run_u32()
    run_i32()
    run_u64()
    run_i64()

