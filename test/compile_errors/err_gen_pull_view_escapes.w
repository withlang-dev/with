//! expect-error: returned ephemeral value may outlive its origin 'v'

// D69 (§13.4, #1732): the iterator pulled from a generator whose argument
// is a view is as ephemeral as that generator value: it cannot leave the
// scope of the viewed place.
use std.task.Pulled

gen fn nonempty(lines: &Vec[str]) -> &str:
    for line in lines:
        if line.len() > 0:
            yield line

fn escaped() -> Pulled[&str]:
    let v: Vec[str] = ["a".clone(), "c".clone()]
    nonempty(&v).pull()

fn main:
    var p = escaped()
    print(p.next().unwrap())
