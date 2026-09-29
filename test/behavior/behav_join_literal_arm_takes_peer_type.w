//! expect-stdout: 5 5 3000000000 7 300

// §4.2.1/§4.2.6: with no enclosing demand, an untyped literal arm of an
// `if` or `match` takes its type from the typed arms, in either arm order,
// as a literal operand takes its peer's. `if c: 0 else: n as u32` joined as
// i32 (the literal's default, the left arm at equal width) and the u32 arm
// changed sign silently; the arms the other way round joined at u32
// (rt/windows_x86_64.w's Sleep(ms), #1886's tree).
fn takes_u32(ms: u32) -> u32: ms
fn takes_u8(b: u8) -> u8: b

fn clamp_ms(ns: i64, zero_first: bool) -> u32:
    let ms = if zero_first:
        if ns <= 0: 0 else: ((ns + 999999) / 1000000) as u32
    else:
        if ns > 0: ((ns + 999999) / 1000000) as u32 else: 0
    takes_u32(ms)

fn main:
    // A typed arm wider than the literal's default: the literal follows it.
    let big: u32 = 3000000000
    let picked = if big > 0: big else: 1
    // match arms, literal first and typed last.
    let n: u8 = 7
    let m = match n:
        0 => 1
        _ => n
    // Two literal arms alone still default; the width comes from the demand.
    let w: i64 = if n > 3: 300 else: 0
    print(f"{clamp_ms(4500000, true)} {clamp_ms(4500000, false)} {takes_u32(picked)} {takes_u8(m)} {w}")
