//! expect-stdout: ok

// D43: a missing match arm forces an unannotated tail to Unit, even when
// every written arm has the same value type. The no-match path has no
// result to read; Sema's type must say that before MIR builds the join.
enum Event { Click | Key | Scroll }
global var seen: i32

fn partial(e: Event):
    match e:
        Key => seen = 5

fn partial_block(e: Event):
    seen = 2
    match e:
        Click => seen = 3
        Key => seen = 4

fn main:
    let matched: Unit = partial(.Key)
    assert(seen == 5)
    let missed: Unit = partial(.Scroll)
    assert(seen == 5)
    let block_matched: Unit = partial_block(.Click)
    assert(seen == 3)
    let block_missed: Unit = partial_block(.Scroll)
    assert(seen == 2)
    print("ok")
