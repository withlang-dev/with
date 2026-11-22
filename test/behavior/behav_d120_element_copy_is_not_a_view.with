//! expect-stdout: same_buf true
//! expect-stdout: out 1 2 3 4 5 6

// D120 §2.3: an element copied out of a value list (`out[i] = state[l]`,
// an integer) carries no view into the list, so the list's later handoff
// is still its last use and is taken, not retained: the callee mutates
// the same buffer and nothing is copied. The last-use pass once made
// `out` a "view" of `state` through that element copy and kept every
// handoff a retained copy (the compiler's own stage 4 dataflow copied its
// state vector at every statement, 239,743 times per self-check).

fn step(state_in: List[i32], k: i32) -> List[i32]:
    var state = state_in
    state[k] = k + 1
    state

fn main:
    var state: List[i32] = List.with_capacity(8)
    var out: List[i32] = List.with_capacity(8)
    for i in 0..6:
        state.push(0)
        out.push(0)
    let orig = state.as_ptr() as usize
    var same = true
    var changed = true
    while changed:
        changed = false
        for k in 0..6:
            state = step(state, k)
            if state.as_ptr() as usize != orig: same = false
        for l in 0..6:
            if out[l] != state[l]:
                out[l] = state[l]
                changed = true
    print("same_buf " ++ (if same: "true" else: "false"))
    print(f"out {out[0]} {out[1]} {out[2]} {out[3]} {out[4]} {out[5]}")
