//! expect-stdout: ok

error NarrowError =
    | Bad

type Raw { value: i32 }
impl Raw:
    fn drop(move self: Self): ()

type Parsed { value: i32 }
impl Parsed:
    fn drop(move self: Self): ()

fn parse(raw: Raw) -> Result[Parsed, NarrowError]:
    Ok(Parsed { value: raw.value + 1 })

fn validate(parsed: Parsed) -> Result[i32, NarrowError]:
    Ok(parsed.value + 1)

fn narrow() -> Result[i32, NarrowError]:
    let item = Raw { value: 40 }
    let item = parse(item)?
    let item = validate(item)?
    Ok(item)

fn main:
    assert(narrow().unwrap() == 42)
    print("ok")
