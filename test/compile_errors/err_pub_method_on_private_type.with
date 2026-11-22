//! expect-check-fail: pub fn 'Parser.new' names private type 'Parser' in its signature
// §18.1: a `pub` method of a private type is unreachable by construction.

type Parser { pos: i32 }

pub fn Parser.new() -> Parser:
    Parser { pos: 0 }

fn main:
    let p = Parser.new()
    let _ = p.pos
