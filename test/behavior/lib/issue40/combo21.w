error E =
    | Bad(msg: str)

type Value = {
    raw: u64,
    ok: bool,
}

fn get_value(ok: bool) -> Result[Value, E]:
    if ok:
        return Ok(Value { raw: 1, ok: true })
    Err(.Bad("bad"))

fn value_as_i32(value: Value) -> Result[i32, E]:
    if value.ok:
        return Ok(value.raw as i32)
    Err(.Bad("bad"))

fn once(ok: bool) -> Result[i32, E]:
    let value = get_value(ok)?
    let number = value_as_i32(value)?
    Ok(number + 1)

pub fn sentinel -> i32:
    0
