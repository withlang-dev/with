//! expect-stdout: ok

use issue41.ir
use issue41.parser

fn text1 -> str:
    "short\n"

fn text2 -> str:
    "short\n"

fn count1() -> Result[i32, ParseError]:
    let prog = parse_text(text1())?
    Ok(program_count(prog))

fn count2() -> Result[i32, ParseError]:
    let prog = parse_text(text2())?
    Ok(program_count(prog))

fn main:
    let first = match count1():
        Ok(v) => v
        Err(_) =>
            assert(false)
            0
    let second = match count2():
        Ok(v) => v
        Err(_) =>
            assert(false)
            0
    assert(first == 2)
    assert(second == 2)
    print("ok")
