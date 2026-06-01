comptime fn comptime_chain() -> str:
    "ct" ++
    "-a" ++
    "-b" ++
    "-c" ++
    "-d" ++
    "-e" ++
    "-f" ++
    "-g"

const COMPTIME_CHAIN: str = comptime comptime_chain()

fn runtime_chain(prefix: str) -> str:
    prefix ++
    "-a" ++
    "-b" ++
    "-c" ++
    "-d" ++
    "-e" ++
    "-f" ++
    "-g"

fn main:
    assert(COMPTIME_CHAIN == "ct-a-b-c-d-e-f-g")
    assert(runtime_chain("rt") == "rt-a-b-c-d-e-f-g")
