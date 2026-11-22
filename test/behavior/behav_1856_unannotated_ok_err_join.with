//! expect-stdout: Ok(2)
//! expect-stdout: Err("e")
//! expect-stdout: Ok(2)
//! expect-stdout: Err("x")

// #1856 (§9.7, §21.1 contextual joins): an `if` or `match` whose arms are
// `Ok(a)` and `Err(b)` has one type, `Result[A, B]`, with no annotation on
// the binding: each arm fixes the type argument it names and the join
// combines them, as `Some(x)`/`None` already joins to `Option[T]`.

fn pick(c: bool, s: str):
    let r = if c: Ok(s.len()) else: Err("e" ++ "")
    print(f"{r:?}")

fn remap(q: Result[str, str]):
    let n = match q:
        Ok(x) => Ok(x.len())
        Err(e) => Err(e)
    print(f"{n:?}")

fn main:
    pick(true, "ab")
    pick(false, "ab")
    remap(Ok("ab" ++ ""))
    remap(Err("x" ++ ""))
