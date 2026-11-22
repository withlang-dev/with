error E =
    | A

fn low -> Result[i32, E]:
    Ok(1)

fn wrap -> Result[i32, E]:
    match low():
        Ok(v) => Ok(v)
        Err(.A) => Err(.A)

fn main:
    let out = match wrap():
        Ok(v) => v
        Err(_) => 0
    assert(out == 1)
