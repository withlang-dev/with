// Wave 6: pattern bindings may reuse names across control-flow branches.

type Maybe = Some(i32) | None

fn project(m: Maybe, flag: bool) -> i32:
    let base = 1
    let branch = if flag:
        match m
            Some(v) -> v
            None -> 0
    else
        match m
            Some(v) -> v + 1
            None -> 1
    base + branch

fn main -> i32:
    assert(project(Some(2), true) == 3)
    assert(project(Some(2), false) == 4)
    0
