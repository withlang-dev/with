//! expect-stdout: ok

use demo21.ir
use demo21.program

pub error E = Bad

fn make_source(entry: str) -> Result[ProgramSource, E]:
    Ok(ProgramSource {
        ir: empty_ir(),
        ir_text: "",
        entry,
        spec_constants: Vec.new(),
    })

fn main:
    let source = make_source("main").unwrap()
    assert(source.ir.num_params == 0)
    assert(source.entry == "main")
    assert(source.spec_constants.len() == 0)
    print("ok")
