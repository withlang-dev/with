//! expect-stdout: 1 3 3
//! expect-stdout: 10 2 20 40
//! expect-stdout: 4

// D115 (§9.7): over a place, a slice or a List, the pattern observes its
// subject: elements bind as views and `rest` is a `[]T` view of the
// elements between the matched ends. The subject stays whole.
fn first_and_rest(s: []i32) -> i32:
    let [first, ..rest] = s else return -1
    print(f"{first} {rest.len()} {rest[1]}")
    0

fn main:
    let arr: [i32; 4] = [1, 2, 3, 4]
    let _ = first_and_rest(arr[0..4])
    let v = [10, 20, 30, 40]
    match v:
        [a, ..rest, z] => print(f"{a} {rest.len()} {rest[0]} {z}")
        _ => print("short")
    print(v.len())
