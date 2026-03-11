//! expect-stdout: 5
//! expect-stdout: none
fn main:
    // filter: keep Some(5) because 5 > 3
    let a: Option[i32] = Some(5)
    let filtered = a.filter(|x| x > 3)
    if filtered.is_some():
        println(int_to_string(filtered.unwrap()))

    // filter: discard Some(1) because 1 > 3 is false
    let b: Option[i32] = Some(1)
    let filtered2 = b.filter(|x| x > 3)
    if filtered2.is_none():
        println("none")
