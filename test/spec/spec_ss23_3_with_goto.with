//! expect-stdout: jump=[R|in] nojump=[R|after]
// §23.3.1.7 / §7.7.1.5: `goto 'l` inside a `with` block targets a visible
// label in the enclosing function; the guard is released before the labeled
// continuation runs. The explicit `return` keeps this fixture focused on guard
// cleanup; implicit labeled tails are covered by behav_labeled_tail_goto (#640).
var LOG = ""
type Guard {}
impl Scoped[i32] for Guard:
    fn with_enter(self: &Self) -> i32: 0
    fn with_exit(self: &Self) -> Unit: LOG = LOG ++ "R"

fn goto_path(jump: bool) -> str:
    LOG = ""
    let g = Guard {}
    var step = "start"
    with g as d:
        step = "in"
        if jump:
            goto 'done
        step = "after"
    'done:
        return LOG ++ "|" ++ step

fn main:
    print(f"jump=[{goto_path(true)}] nojump=[{goto_path(false)}]")
