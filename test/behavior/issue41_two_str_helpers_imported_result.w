//! expect-stdout: ok

use issue41.ir
use issue41.parser

fn text1 -> str:
    "short\n"

fn text2 -> str:
    "short\n"

fn t1:
    let prog = match parse_text(text1()):
        Ok(v) => v
        Err(_) =>
            assert(false)
            program_empty()
    assert(prog.count == 2)
    assert(program_count(prog) == 2)

fn t2:
    let prog = match parse_text(text2()):
        Ok(v) => v
        Err(_) =>
            assert(false)
            program_empty()
    assert(prog.count == 2)
    assert(program_count(prog) == 2)

fn main:
    t1()
    t2()
    print("ok")
