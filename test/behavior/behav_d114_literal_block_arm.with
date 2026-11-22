//! expect-stdout: 7 -1 9 3

// §4.2.1 rule 8 (D114): a literal arm takes the typed arms' type when the
// literal is a block's tail; the block's statements type nothing.
fn parse(ok: bool) -> Result[i32, str]:
    if ok: Ok(7) else: Err("no")

fn note(s: str): ()

fn wants(x: i32): x

fn main:
    let a = match parse(true):
        Ok(v) => v
        Err(e) =>
            note(e)
            0
    let b = match parse(false):
        Ok(v) => v
        Err(e) =>
            note(e)
            -1
    let c: u8 = 9
    let d = if c > 3:
        c
    else:
        note("small")
        0
    print(f"{wants(a)} {wants(b)} {d} {wants(3)}")
