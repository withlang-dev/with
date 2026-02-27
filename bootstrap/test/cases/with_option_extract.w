// Test with Option[T] as v: extracts inner value, skips if None
fn maybe_int(x: i32) -> Option[i32]:
    if x > 0
        Some(x)
    else
        None

fn main -> i32:
    let opt1 = maybe_int(42)
    with opt1 as v:
        println(v)
    let opt2 = maybe_int(-1)
    with opt2 as v:
        println(v)
    println("done")
