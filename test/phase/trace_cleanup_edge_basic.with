//! args: --trace-cleanup-edge choose:bb0->bb1
//! expect-check-stdout: trace-cleanup-edge choose:bb0->bb1
//! expect-check-stdout: edge=bb0->bb1
//! expect-check-stdout: term: switchInt

fn choose(flag: bool):
    if flag:
        let x = 1
        let _ = x
    else:
        let y = 2
        let _ = y

fn main:
    choose(true)
