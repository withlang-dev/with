//! expect-stdout: alone true 3
//! expect-stdout: after byte true 4 7
//! expect-stdout: two true true 5 6
//! expect-stdout: loop 4
//! expect-stdout: drop hello 8

// #2042: a `move` closure's environment holds its captures by value in a
// heap cell {drop_fn, clone_fn, env}. The cell and the environment were the
// literal LLVM structs of their member types, so an `@[align(32)]` capture
// (§16.4) sat where LLVM's 8-byte view of its i8-padded body put it: the
// environment at offset 16 of a 16-aligned cell, the record at 16 mod 32.
// Both now take TypeLayout's placement and the cell its alignment.

type Al { a: i8, @[align(32)] v: i64 }
type Named { @[align(64)] s: str, k: i64 }

fn main:
    let held = Al { a: 5, v: 3 }
    let alone = move () => ((&raw const held.v as i64) % 32 == 0, held.v)
    let (a_ok, a_v) = alone()
    print(f"alone {a_ok} {a_v}")

    let byte: i8 = 7
    let second = Al { a: 1, v: 4 }
    let after = move () => ((&raw const second.v as i64) % 32 == 0, second.v, byte)
    let (b_ok, b_v, b_byte) = after()
    print(f"after byte {b_ok} {b_v} {b_byte}")

    let x = Al { a: 2, v: 5 }
    let y = Al { a: 3, v: 6 }
    let both = move () => ((&raw const x.v as i64) % 32 == 0, (&raw const y.v as i64) % 32 == 0, x.v, y.v)
    let (x_ok, y_ok, x_v, y_v) = both()
    print(f"two {x_ok} {y_ok} {x_v} {y_v}")

    var aligned = 0
    for i in 0..4:
        let item = Al { a: 0, v: i as i64 }
        let probe = move () => (&raw const item.v as i64) % 32 == 0
        if probe(): aligned += 1
    print(f"loop {aligned}")

    let named = Named { s: "hel" ++ "lo", k: 8 }
    let show = move () => if (&raw const named.s as i64) % 64 == 0: f"{named.s} {named.k}" else: "misaligned"
    print(f"drop {show()}")
