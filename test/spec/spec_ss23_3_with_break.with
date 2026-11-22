//! expect-stdout: last=1 rel=3
// §23.3.1.4: `break` inside a `with` block breaks the enclosing loop; the
// guard is released once per iteration, including the breaking iteration.
var REL = 0
type Guard {}
impl Scoped[i32] for Guard:
    fn with_enter(self: &Self) -> i32: 0
    fn with_exit(self: &Self) -> Unit: REL = REL + 1

fn run() -> i32:
    var last = -1
    for i in 0..5:
        let g = Guard {}
        with g as d:
            if i == 2:
                break
            last = i
    last

fn main:
    let last = run()
    print(f"last={last} rel={REL}")
