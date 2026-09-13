//! expect-error: cannot consume read-only view binding `observed`

fn consume(value: str): print(value)
fn observe(source: &str):
    let observed = *source
    consume(observed)

fn main: observe("alpha")
