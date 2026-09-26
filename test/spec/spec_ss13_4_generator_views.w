//! expect-stdout: ok
// Spec test: Section 13.4 — Views (D69). A generator may yield a view of its
// own locals or of what its arguments view; the view is valid for the run of
// the consumer's body. Owned values move out to the consumer as before.

gen fn owned_words -> str:
    let first = "hello"
    yield first
    let second = "world"
    yield second

gen fn labels(count: i32) -> &str:
    var buf = ""
    for i in 0..count:
        buf = f"item-{i}"
        yield &buf

gen fn nonempty(lines: &Vec[str]) -> &str:
    for line in lines:
        if line.len() > 0:
            yield line

fn test_owned_values_move_to_the_consumer:
    var joined = ""
    for word in owned_words():
        joined = joined ++ word
    assert(joined == "helloworld")

fn test_view_of_own_local:
    var count = 0
    var last = ""
    for label in labels(3):
        count += 1
        last = label.clone()
    assert(count == 3)
    assert(last == "item-2")

fn test_view_into_argument:
    let lines: Vec[str] = ["a".clone(), "".clone(), "c".clone()]
    var joined = ""
    for line in nonempty(&lines):
        joined = joined ++ line
    assert(joined == "ac")

fn main:
    test_owned_values_move_to_the_consumer()
    test_view_of_own_local()
    test_view_into_argument()
    print("ok")
