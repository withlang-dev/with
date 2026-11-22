//! expect-stdout: bhits=4 ckept=3 relb=4 relc=6
// §23.3.1.6: labeled `break 'l` / `continue 'l` inside a `with` block target
// the enclosing labeled loop; `with` does not hide labels.
var REL = 0
type Guard {}
impl Scoped[i32] for Guard:
    fn with_enter(self: &Self) -> i32: 0
    fn with_exit(self: &Self) -> Unit: REL = REL + 1

fn labeled_break() -> i32:
    var hits = 0
    'outer for i in 0..3:
        for j in 0..3:
            let g = Guard {}
            with g as d:
                hits = hits + 1
                if i == 1 and j == 0:
                    break 'outer
    hits

fn labeled_continue() -> i32:
    var kept = 0
    'outer for i in 0..3:
        for j in 0..3:
            let g = Guard {}
            with g as d:
                if j == 1:
                    continue 'outer
            kept = kept + 1
    kept

fn main:
    REL = 0
    let b = labeled_break()
    let rb = REL
    REL = 0
    let c = labeled_continue()
    let rc = REL
    print(f"bhits={b} ckept={c} relb={rb} relc={rc}")
