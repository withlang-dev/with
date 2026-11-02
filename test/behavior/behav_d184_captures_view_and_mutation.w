//! expect-stdout: a
//! expect-stdout: 2
//! expect-stdout: 3 isize
//! expect-stdout: ok

// D184 (§29.15): a script binding may hold a view and a helper may capture
// it; a helper mutates a captured collection in place; a helper's own
// parameter shadows a script binding (D173); an integer-literal binding a
// helper reads first is settled as isize.

let names: List[str] = ["a".to_owned(), "b".to_owned()]
let view = &names
fn first() -> str: view[0]
print(first())

var sink: List[i32] = []
fn add(v: i32): sink.push(v)
add(1)
add(2)
print(sink.len())

var count = 0
fn count_to(count: i32) -> i32: count + 1
fn bump(): count = count + 1
bump()
bump()
bump()
print(f"{count} {if count_to(1) == 2: \"isize\" else: \"?\"}")
print("ok")
