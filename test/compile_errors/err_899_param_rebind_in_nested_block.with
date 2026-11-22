//! expect-check-fail: shadowing is not allowed for 'state'
// #899 (§29.8): the consuming-rebind exception reaches a parameter from its
// function body's own scope only; a nested block that consumes the
// parameter still may not reuse its name (the old binding is not a local of
// that block).
type Query { alias: Option[str] }

fn consume_field(state: Query, deep: bool) -> isize:
    if deep:
        var state = move state
        return (move state.alias).unwrap().len()
    0

fn main:
    print(consume_field(Query { alias: Some("abc") }, true))
