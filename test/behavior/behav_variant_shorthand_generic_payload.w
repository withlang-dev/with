//! expect-stdout: ok

// #933: `.Some(v.get(0))` — a generic-method-call payload inside a variant
// shorthand — trapped the compiler (the call result was typed unit and
// aggregated into the Option). Both the view and the owned payload shapes
// must compile and carry the value.
fn first_view(v: &Vec[i32]) -> Option[&i32]: .Some(v.get(0))
fn first_owned(v: &Vec[i32]) -> Option[i32]: .Some(v.get(0))
fn first_str(v: &Vec[str]) -> Option[&str]: .Some(v.get(0))

fn main:
    let xs: Vec[i32] = [7, 8]
    match first_view(xs):
        .Some(p) => if *p != 7:
            print("FAIL view")
            return
        .None =>
            print("FAIL view none")
            return
    match first_owned(xs):
        .Some(n) => if n != 7:
            print("FAIL owned")
            return
        .None =>
            print("FAIL owned none")
            return
    // Auto-reference direction: an owned local into a `&T` payload.
    let n = 5
    let viewed: Option[&i32] = .Some(n)
    match viewed:
        .Some(p) => if *p != 5:
            print("FAIL autoref payload")
            return
        .None =>
            print("FAIL autoref none")
            return
    var ss: Vec[str] = Vec.new()
    ss.push("hello")
    match first_str(ss):
        .Some(s) => if s.len() != 5:
            print("FAIL str")
            return
        .None =>
            print("FAIL str none")
            return
    print("ok")
