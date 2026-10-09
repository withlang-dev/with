//! expect-stdout: ok

// D115 (§9.7): `rest` names the elements between the matched ends; over a
// place (here a parameter's array observed by a `let`) it is a `[]T` view.
fn summarize(arr: [i32; 4]) -> i64:
    let [first, ..middle, last] = arr else return -1
    first + middle[0] + middle[1] + last + middle.len()

fn main:
    assert(summarize([10, 20, 30, 40]) == 102)
    print("ok")
