//! expect-stdout: 3
// #899 (§29.8): a parameter may be rebound by a binding whose initializer
// consumes it — `var state = move state` — as a local already may. It was
// "shadowing is not allowed for 'state'", and D32's respelling of a consuming
// parameter needed a second name.
type Query { alias: Option[str] }

fn consume_field(state: Query) -> isize:
    var state = move state
    (move state.alias).unwrap().len()

fn main:
    print(consume_field(Query { alias: Some("abc") }))
