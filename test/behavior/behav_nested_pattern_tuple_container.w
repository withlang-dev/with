//! expect-stdout: ok

error ParseErr =
    Bad(msg: str)

fn tag(pair: (Result[i32, ParseErr], i32)) -> i32:
    match pair:
        (Err(.Bad(msg)), code) if msg == "oops" => code
        (Ok(v), code) => v + code
        _ => -1

fn main:
    assert(tag((Err(.Bad("oops")), 3)) == 3)
    assert(tag((Ok(7), 5)) == 12)
    print("ok")
