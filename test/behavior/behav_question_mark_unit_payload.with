//! expect-stdout: ok 3 neg:-2 stopped

// `?` over a Unit payload, `Result[Unit, E]`: as a statement, on a binding,
// and with a `str` error. (`Option[Unit]` waits on #1218: a function
// returning it does not compile at all.) The pass path
// has nothing to extract; typing the payload as the whole Result made
// codegen load an unsized field and the compiler died in LLVM.
type Failure { code: i32 }

fn step(n: i32) -> Result[Unit, Failure]:
    if n < 0: return Err(Failure { code: n })
    Ok(())

fn run(n: i32) -> Result[i32, Failure]:
    step(n)?
    n + 1

fn run_bound(n: i32) -> Result[Unit, Failure]:
    let stepped = step(n)
    stepped?
    step(n + 1)?
    Ok(())

fn named(n: i32) -> Result[Unit, str]:
    if n < 0: return Err(f"neg:{n}")
    Ok(())

fn run_named(n: i32) -> Result[str, str]:
    named(n)?
    "fine"

fn main:
    var out = ""
    match run_bound(1):
        Ok(_) => out = out ++ "ok"
        Err(e) => out = out ++ f"err {e.code}"
    match run(2):
        Ok(v) => out = out ++ f" {v}"
        Err(e) => out = out ++ f" err {e.code}"
    match run_named(-2):
        Ok(s) => out = out ++ " " ++ s
        Err(e) => out = out ++ " " ++ e
    match run(-5):
        Ok(v) => out = out ++ f" {v}"
        Err(_) => out = out ++ " stopped"
    print(out)
