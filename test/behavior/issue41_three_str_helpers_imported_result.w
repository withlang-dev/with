//! expect-stdout: ok

use issue41.ir
use issue41.parser

fn text1 -> str:
    "short\n"

fn text2 -> str:
    "short\n"

fn text3 -> str:
    "short\n"

fn verify(text: str):
    let prog = match parse_text(text):
        Ok(v) => v
        Err(_) =>
            assert(false)
            program_empty()
    assert(prog.count == 2)
    assert(program_count(prog) == 2)

fn t1:
    verify(text1())

fn t2:
    verify(text2())

fn t3:
    verify(text3())

fn main:
    t1()
    t2()
    t3()
    print("ok")
