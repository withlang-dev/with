//! expect-error: slice rest binding for dynamic slices is not implemented yet

// #1389: a named rest over a Vec is the dynamic-slice rest binding, still
// reported loudly (§9.7 shows it as a slice in one example and as a count
// for fixed-size arrays; the dynamic form is not decided).
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    match v:
        [first, ..rest] => print(f"{first}")
        _ => print("none")
