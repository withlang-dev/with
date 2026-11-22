//! expect-stdout: sum=4 rel=5
// §23.3.1.5: `continue` inside a `with` block continues the enclosing loop;
// the guard is still released on the skipped iterations.
var REL = 0
type Guard {}
impl Scoped[i32] for Guard:
    fn with_enter(self: &Self) -> i32: 0
    fn with_exit(self: &Self) -> Unit: REL = REL + 1

fn run() -> i32:
    var sum = 0
    for i in 0..5:
        let g = Guard {}
        with g as d:
            if i % 2 == 0:
                continue
            sum = sum + i
    sum

fn main:
    print(f"sum={run()} rel={REL}")
