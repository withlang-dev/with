//! expect-stdout: parser issue334 final else expr passed

fn inline_colon -> i32:
    if false: 1 else: 2

fn indented_colon -> i32:
    if false:
        1
    else: 2

fn braced -> i32:
    if false { 1 } else: 2

fn mixed_chain(x: i32) -> i32:
    if x < 0:
        -1
    else if x == 0 { 0 }
    else: 1

fn chain_continuation -> i32:
    if false: 1 else if true: 2 else: 3

fn main:
    assert(inline_colon() == 2)
    assert(indented_colon() == 2)
    assert(braced() == 2)
    assert(mixed_chain(-1) == -1)
    assert(mixed_chain(0) == 0)
    assert(mixed_chain(1) == 1)
    assert(chain_continuation() == 2)
    print("parser issue334 final else expr passed")
