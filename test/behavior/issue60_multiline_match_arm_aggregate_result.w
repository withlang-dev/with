//! expect-stdout: ok

type Source {
    ir: Vec[i32],
    entry: str,
}

error ParseErr =
    Bad

fn parsed_source() -> Source:
    let ir: Vec[i32] = Vec.new()
    ir.push(7)
    ir.push(8)
    Source { ir, entry: "main" }

fn parse(ok: bool) -> Result[Source, ParseErr]:
    if ok: Ok(parsed_source()) else Err(.Bad)

fn compile_text_source(ok: bool) -> Source:
    match parse(ok):
        Ok(v) => v
        Err(_) =>
            assert(true)
            let fallback: Vec[i32] = Vec.new()
            Source { ir: fallback, entry: "fallback" }

fn main:
    let ok_src = compile_text_source(true)
    assert(ok_src.entry == "main")
    assert(ok_src.ir.len() == 2)
    assert(ok_src.ir[0] == 7)
    assert(ok_src.ir[1] == 8)

    let err_src = compile_text_source(false)
    assert(err_src.entry == "fallback")
    assert(err_src.ir.len() == 0)

    print("ok")
